/*
 * @author Matthieu Guffroy
 * 
 * Test of the CAS client
 */

import mattgu74.cas

cas_conf = {
  url = "https://cas.server/cas/" ; // <<-- sample url
  service = "http://localhost:8080"
 } : Cas.config

myCas = Cas(cas_conf)

start() =
  body = <> Test du module CAS </><br />
         <a href="/CAS/login"> Login </a><br />
         <>{myCas.get_status()}</>
  Resource.html("CAS module", body)


urls : Parser.general_parser(http_request -> resource) =
  parser
  | result={myCas.resource} -> _req ->
      result
  | .* -> _req ->
      start()


server = Server.make(urls)
