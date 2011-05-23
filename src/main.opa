/*
 * @author Matthieu Guffroy
 * 
 * Test of the CAS client
 */

import mattgu74.cas

cas_conf = {
  url = "https://cas.server.domain/cas/" ; // <<-- sample url
  service = "http://localhost:8080"
 } : Cas.config

myCas = Cas(cas_conf)

start() =
  status = myCas.get_status()
  msg = match status with 
    | {logged = user} -> <>Welcome {user}</><br />
                         <a href="/CAS/logout"> Logout </a>
    | {unlogged} -> <> You're not logged-in </><br />
                    <a href="/CAS/login"> Login </a>

  body = <> Test du module CAS </><br />
         <>{msg}</>

  Resource.html("CAS module", body)


urls : Parser.general_parser(http_request -> resource) =
  parser
  | result={myCas.resource} -> _req ->
      result
  | .* -> _req ->
      start()


server = Server.make(urls)
