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
    service : string // Url of the service
  }

type Cas.ticket = { ticket : string } / {no}

type Cas.status = { logged : string } / { unlogged }
type Cas.info = UserContext.t(Cas.status)

Cas(conf : Cas.config) = {{

  @private state = UserContext.make({ unlogged } : Cas.status)

  @private login_url() =
    String.concat("", [conf.url, "login?service=", conf.service, "/CAS/ticket"])

  @private logout_url() =
    String.concat("", [conf.url, "logout?url=", conf.service])

  @private xml_match(xml) = 
    match xml with
      | {namespace = name; tag = tag; args = args;
        content = cont; specific_attributes = _ } -> {name = name ; tag = tag ; args = args ; cont = cont} 
      | _ -> { name = "" ; tag = "" ; args = [] ; cont = []} 

  @private status_from_xml(xml) =
   match xml_match(xml) with
    | {name = "cas"; tag="serviceResponse" ; args=_ ; cont=c1} -> 
      funa(x1) = 
        match xml_match(x1) with 
          | {name = "cas"; tag="authenticationSuccess" ; ... } -> true
          | _ -> false
        end
      next1 = List.find(funa,c1)
      match next1 with
        | {some = s1} -> 
          funb(x2) = 
            match xml_match(x2) with 
              | {name = "cas"; tag="user" ; ... } -> true
              | _ -> false
             end
            w = xml_match(s1)
            next2 = List.find(funb,w.cont)
            match next2 with
              | {some = s2} -> w = xml_match(s2)
                               match List.head(w.cont) with
                                | {text = t} -> {logged = t}
                                | _ -> {unlogged}
                               end
              | {none} -> {unlogged}
             end
        | _ -> { unlogged }
       end
    | _ -> { unlogged }

  @private server_validate(uri) =
    match WebClient.Result.as_xml(WebClient.Get.try_get(uri)) with
      | {failure = _} -> void
      | {~success}    -> match WebClient.Result.get_class(success) with
        | {success} -> do UserContext.change((_ -> status_from_xml(success.content) ), state)
                       void
        | _         -> void
    end

  get_status() =
    match UserContext.execute(( a -> a), state) with
     | {logged = l} -> l
     | {unlogged} -> "Unlogged"

  validate(t) =
   the_uri = Uri.of_string( String.concat( "" , [conf.url, "serviceValidate?service=", conf.service, "/CAS/ticket&ticket=", t]))
   match the_uri with
     | {some = uri} -> server_validate(uri)
     | {none} -> void


  start() =
    body = <>CAS module</>
    Resource.html("CAS module", body)

  login() =
    Resource.redirection_page("",<></>,{success},0,login_url())

  logout() =
    do UserContext.change(( _ -> { unlogged }), state) 
    Resource.redirection_page("",<></>,{success},0,logout_url())

  ticket(n) = 
    myParser =
     parser
     | "?ticket=" n=(.*) ->
       { ticket = Text.to_string(n) }
     | .* -> 
       {no}
    ticket = Parser.parse(myParser, n)
    do match ticket with
       | { ticket = t } -> validate(t)
       | {no} -> void
    Resource.redirection_page("",<></>,{success},0,conf.service)

  resource : Parser.general_parser(resource) =
    parser
    | "/CAS/login" ->
      login()
    | "/CAS/logout" ->
      logout()
    | "/CAS/ticket" n=(.*) ->
      ticket(Text.to_string(n)) 
    | "/CAS" .* ->
      start()

}}
