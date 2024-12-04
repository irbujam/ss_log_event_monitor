const { ApiPromise, WsProvider } = require('@polkadot/api');
const { encodeAddress } = require('@polkadot/util-crypto');

// Save the original process.stdout.write function to restore later
const originalStdoutWrite = process.stdout.write;

// Redirect stdout and stderr to null to suppress all logs
//process.stdout.write = function() {};  // Suppresses all stdout (info/debug)
process.stderr.write = function() {};  // Suppresses all stderr (error/warnings)

async function getBalance(io_node_url, io_vlt_address_arr) {

	// Connect to a node (replace with your desired node URL)
	const provider = new WsProvider(io_node_url);
	const api = await ApiPromise.create({ provider });

	// Fetch the account balance
	var resp_json = '{"Response":';
	var _total_balance = 0;
	var iterator = 0;
	for (const io_vlt_address_arr_item of io_vlt_address_arr) {
		_vlt_addr_ = io_vlt_address_arr_item.acct_id.toString();
		//process.stdout.write(_vlt_addr_.toString());
		
		base58Addr = _vlt_addr_;
		//encoded_addr = encodeAddress(_vlt_addr_, substrate_addr_prefix);

		const { data: { free: balance } } = await api.query.system.account(base58Addr);
		_total_balance += Number(balance);
		if (iterator == 0) {
			resp_json += '[{"address_id":' + '"' + base58Addr.toString() + '","balance":"' + balance.toString() + '"}';
		}
		else {
			resp_json += ',{"address_id":' + '"' + base58Addr.toString() + '","balance":"' + balance.toString() + '"}';
		}
		iterator += 1;
	}
	
	if (iterator > 0) {
		//add overall balance to response
		resp_json += ',{"address_id":' + '"' + 'overall' + '","balance":"' + _total_balance.toString() + '"}';
		resp_json += ']';
	}
	//finalize response
	resp_json += '}';

	// Restore stdout to display the balance
	process.stdout.write = originalStdoutWrite;

	process.stdout.write(resp_json);  // Output balance

	// Disconnect from the node after querying
	await api.disconnect();
}

/*
// Get the URL and accountId passed as arguments (argv[2] for URL, argv[3] for account ID)
const nodeUrl = process.argv[2];
const accountId = process.argv[3];

if (nodeUrl && accountId) {
	getBalance(nodeUrl, accountId).catch(console.error);
}
else {
	console.error("Both URL and Account ID are required.");
};
*/

const nodeUrl = process.argv[2];
//console.log('Node url:', nodeUrl);  // Logs any regular argument passed

const vltAddJsonString = process.argv[3]; // Assume the first argument is a JSON string

try {
	const vltAddressArr = JSON.parse(vltAddJsonString);
	//console.log('vltAddressArr:', vltAddressArr);  
	getBalance(nodeUrl, vltAddressArr).catch(console.error);
}
catch (error) {
	console.error('Error parsing address JSON:', error);
}
