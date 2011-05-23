/**
 * An opa CAS client
 *
 * See http://www.jasig.org/cas/protocol
 *
 * @auhtor Matthieu Guffroy
 */

/*
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/*
 * Warning This module is in construction only a few part of the protocol is
 * handled...
 */

package mattgu74.cas

type Cas.config = 
  {
    url : string ;  // Url of the cas service
    service : string // Url of the serve
  }

type Cas.ticket = { ticket : string } / {no}

type Cas.status = { logged : string } / { unlogged }
type Cas.info = UserContext.t(Cas.status)

Cas(conf : Cas.config) = {{

  @private state = UserContext.make({ unlogged } : Cas.status)

  login_url() =
    String.concat("", [conf.url, "login?service=", conf.service, "/CAS/ticket"])

  @private server_validate(uri) =
    match WebClient.Result.as_xml(WebClient.Get.try_get(uri)) with
      | {failure = _} -> <>Error, could not connect></>
      | {~success}    -> match WebClient.Result.get_class(success) with
        | {success} -> do UserContext.change((_ -> { logged = Xmlns.to_string(success.content) } : Cas.status), state)
                       <>{success.content}</>
        | _         -> <>Error {success.code}</>
    end

  get_status() =
    match UserContext.execute(( a -> a), state) with
     | {logged = l} -> l
     | {unlogged} -> "Unlogged"

  validate(t) =
   the_uri = Uri.of_string( String.concat( "" , [conf.url, "serviceValidate?service=", conf.service, "/CAS/ticket&ticket=", t]))
   match the_uri with
     | {some = uri} -> server_validate(uri)
     | {none} -> <> Error 001 </>


  start() =
    body = <>CAS module</>
    Resource.html("CAS module", body)

  login() =
    Resource.default_redirection_page(login_url())

  ticket(n) = 
    myParser =
     parser
     | "?ticket=" n=(.*) ->
       { ticket = Text.to_string(n) }
     | .* -> 
       {no}
    ticket = Parser.parse(myParser, n)
    body = match ticket with
       | { ticket = t } -> validate(t)
       | {no} -> <> Error </>
    Resource.html("CAS module", body)    

  resource : Parser.general_parser(resource) =
    parser
    | "/CAS/login" ->
      login()
    | "/CAS/ticket" n=(.*) ->
      ticket(Text.to_string(n)) 
    | "/CAS" .* ->
      start()

}}
