using Yojak
import Mongo: MongoClient

println("mongoclient start: $(now())")

const client = MongoClient()
Yojak.configure(client)

println("mongoclient end: $(now())")

using API
println("API load end: $(now())")


API.run_algo()