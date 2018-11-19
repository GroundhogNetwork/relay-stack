const BigNumber  = require('bignumber.js')
const web3       = require('web3');
const express    = require('express');
const bodyParser = require('body-parser');
const Tx         = require('ethereumjs-tx');
const web3Utils  = require('web3-utils');
const app = express();
app.use( bodyParser.json() );       // to support JSON-encoded bodies
app.use(bodyParser.urlencoded({     // to support URL-encoded bodies
    extended: true
}));
app.post('/sign', function (req, res) {
    var safe      = req.body.safe;
    var to        = req.body.to;
    var signer    = req.body.signer;
    var value     = req.body.value;
    var safeTxGas = req.body.safeTxGas;
    var dataGas   = req.body.dataGas;
    var nonce     = req.body.nonce;
    web3js = new web3(new web3.providers.HttpProvider("http://ganache:8545"));
    typedData = {
        types: {
            EIP712Domain: [
                { type: "address", name: "verifyingContract" }
            ],
            SafeTx: [
                { type: "address", name: "to" },
                { type: "uint256", name: "value" },
                { type: "bytes",   name: "data" },
                { type: "uint8",   name: "operation" },
                { type: "uint256", name: "safeTxGas" },
                { type: "uint256", name: "dataGas" },
                { type: "uint256", name: "gasPrice" },
                { type: "address", name: "gasToken" },
                { type: "address", name: "refundReceiver" },
                { type: "uint256", name: "nonce" },
            ]
        },
        domain: {
            verifyingContract: safe,
        },
        primaryType: "SafeTx",
        message: {
            to: to,
            value: value,
            data: "0x",
            operation: "0",
            safeTxGas: safeTxGas,
            dataGas: dataGas,
            gasPrice: "1",
            gasToken: "0x0000000000000000000000000000000000000000",
            refundReceiver: "0x0000000000000000000000000000000000000000",
            nonce: nonce
        }
    }
    web3js.currentProvider.sendAsync({
        jsonrpc: "2.0",
        method: "eth_signTypedData", // eth_signTypedData_v3 for MetaMask
        params: [signer, typedData],
        id: new Date().getTime()
    }, function(err, response) {
        if (!err) {
            sig = response.result
            response = {
                data: {
                    r: new BigNumber(sig.slice(2, 66), 16).toString(10),
                    s: new BigNumber(sig.slice(66, 130), 16).toString(10),
                    v: new BigNumber(sig.slice(130, 132), 16).toString(10)
                }
            }
            res.send(response);
        } else {
            console.log(err);
            res.send(err);
        }
    });
})
app.post('/fund/:safeAddress/:amount', function(req, res) {
    let address = '0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1';
    let toAddress = req.params.safeAddress;
    let amount = req.params.amount;
    web3js = new web3(new web3.providers.HttpProvider("http://ganache:8545"));
    web3js.eth.getTransactionCount(address, function(err, count) {
        web3js.eth.getGasPrice(function(err, gasPrice) {
            console.log(gasPrice);
            let rawTransaction = {
                "chainId": 4,
                "from": address,
                "nonce": web3Utils.toHex(count),
                "to": toAddress,
                "value": web3Utils.toHex(web3Utils.toWei(amount, 'ether')),
                "gasPrice": web3Utils.toHex(gasPrice),
                "gasLimit": web3Utils.toHex(210000)
            };
            let privateKey = Buffer.from('4f3edf983ac636a65a842ce7c78d9aa706d3b113bce9c46f30d7d21715b23b1d', 'hex');
            let tx = new Tx(rawTransaction);
            tx.sign(privateKey);
            let serializedTx = tx.serialize();
            web3js.eth.sendRawTransaction('0x' + serializedTx.toString('hex'), function(err, hash) {
                if (!err) {
                    console.log(hash.blockHash);
                    console.log("\n \nTRANSACTIONDONE \n \n");
                    console.log('\u0007');
                    res.send(hash);
                }
                else {
                    console.log(err)
                }
            })
        })
    })
});
app.listen(1337, () => console.log("Listening on port 1337!"))