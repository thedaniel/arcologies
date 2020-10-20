const fs = require('fs')
const WS = require('ws')

const wss = new WS.Server({
    port: 8080
})

// yeah this should be streams and fully async but i'm just hackin here to test

fs.watch('/tmp/arcologies/running.txt', {encoding: 'buffer'}, function (eventType, filename) {
    console.log("change")
    wss.clients.forEach(function each(client) {
        if (client !== wss && client.readyState === WS.OPEN) {
            console.log('sending')
            client.send(fs.readFileSync('/tmp/arcologies/running.txt', {encoding: 'ascii'}));
          }        
    })
})
