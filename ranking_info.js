
async function fRetrieveAccounts(io_nodeUrl, io_vlt_address_arr) {
	const { ApiPromise, WsProvider } = require('@polkadot/api');
	const { encodeAddress } = require('@polkadot/util-crypto');

	// Save the original process.stdout.write function to restore later
	const originalStdoutWrite = process.stdout.write;

	// Redirect stdout and stderr to null to suppress all logs
	//process.stdout.write = function() {};  // Suppresses all stdout (info/debug)
	process.stderr.write = function() {};  // Suppresses all stderr (error/warnings)

	// Substrate node we are connected to and listening to remarks
    const provider = new WsProvider(io_nodeUrl);
    const api = await ApiPromise.create({ provider });

    // Get general information about the node we are connected to
    const [chain, nodeName, nodeVersion] = await Promise.all([
        api.rpc.system.chain(),
        api.rpc.system.name(),
        api.rpc.system.version()
    ]);

    // Adjust how many accounts to query at once.
    let limit = 100;
    let result = [];
    let last_key = "";
	
	// get all accounts from chain and store in array
	while (true) {
        let query = await api.query.system.account.entriesPaged({ args: [], pageSize: limit, startKey: last_key });
        if (query.length == 0) {
            break;
        };

        for (const user of query) {
			let b_match_found = false;
			let address = encodeAddress(user[0].slice(-32));
            let balance = user[1].data.free.toString();
            let reserved_balance = user[1].data.reserved.toString();
            result.push({ address, balance, reserved_balance });
            
			last_key = user[0];
        };
    };
	
	//sort accounts by balance - descending
	result.sort(function(a, b) {
		return parseFloat(b.balance) - parseFloat(a.balance);
	});
	// rerieve array element and position for address from config
	let unique_accounts = result.length;

	//define response
	var resp_json = '{"Response":';
	var _total_balance = 0;
	var _total_reserved_balance = 0;
	var rank = 0;
	//convert base58 to substrate addr
	const substrate_addr_prefix = 42;
	var iterator = 0;
	for (const io_vlt_address_arr_item of io_vlt_address_arr) {
		_vlt_addr_ = io_vlt_address_arr_item.acct_id.toString();
		//process.stdout.write(_vlt_addr_.toString());
		
		base58Addr = _vlt_addr_;
		encoded_addr = encodeAddress(_vlt_addr_, substrate_addr_prefix);

		let my_addr_obj = result.find(oAddr => oAddr.address === encoded_addr);
		let my_addr_obj_index = result.map(oAddr => oAddr.address).indexOf(encoded_addr);
		rank = my_addr_obj_index + 1;

		//prepare response
		_balance = 0;
		_reserved_balance = 0;
		if (my_addr_obj_index >= 0)
		{
			_balance = my_addr_obj.balance;
			_reserved_balance = my_addr_obj.reserved_balance;
		}
		_total_balance += Number(_balance);
		if (iterator == 0) {
			resp_json += '[{"address_id":' + '"' + base58Addr.toString() + '","unique_accounts":"' + unique_accounts.toString() + '","rank_id":"' + rank.toString() + '","balance":"' + _balance.toString() + '","reserved":"' + _reserved_balance.toString() + '"}';
		}
		else {
			resp_json += ',{"address_id":' + '"' + base58Addr.toString() + '","unique_accounts":"' + unique_accounts.toString() + '","rank_id":"' + rank.toString() + '","balance":"' + _balance.toString() + '","reserved":"' + _reserved_balance.toString() + '"}';
		}
		iterator += 1;
	}

	if (iterator > 0) {
		// add overall balance and rank info
		let _overall_rank = 0;
		if (iterator > 1) {
			for( var _i = 0, len = result.length; _i < len; _i++ ) {
				if( result[_i].balance < _total_balance ) {
					_overall_rank = _i + 1;
					break;
				}
			}
		}
		else {
			_overall_rank = rank;
		}
		//add overall balance and rank to response
		resp_json += ',{"address_id":' + '"' + 'overall' + '","unique_accounts":"' + unique_accounts.toString() + '","rank_id":"' + _overall_rank.toString() + '","balance":"' + _total_balance.toString() + '","reserved":"' + _total_reserved_balance.toString() + '"}';
		resp_json += ']';
	}
	//finalize response
	resp_json += '}';

	// Restore stdout to display the balance
	process.stdout.write = originalStdoutWrite;
    
    // send response
	process.stdout.write(resp_json);
	
	await api.disconnect();
}

const nodeUrl = process.argv[2];
//console.log('Node url:', nodeUrl);  // Logs any regular argument passed

const vltAddJsonString = process.argv[3]; // Assume the first argument is a JSON string

try {
	const vltAddressArr = JSON.parse(vltAddJsonString);
	//console.log('Address:', vltAddressArr);
	fRetrieveAccounts(nodeUrl, vltAddressArr).catch(console.error);
}
catch (error) {
	console.error('Error parsing address JSON:', error);
}
