const { ApiPromise, WsProvider } = require('@polkadot/api');

// Save the original process.stdout.write function to restore later
const originalStdoutWrite = process.stdout.write;

// Redirect stdout and stderr to null to suppress all logs
process.stdout.write = function() {};  // Suppresses all stdout (info/debug)
process.stderr.write = function() {};  // Suppresses all stderr (error/warnings)

async function getBalance(io_node_url, io_vlt_addr) {

  // Connect to a node (replace with your desired node URL)
  const provider = new WsProvider(io_node_url);
  const api = await ApiPromise.create({ provider });

  // Fetch the account balance
  const { data: { free: balance } } = await api.query.system.account(io_vlt_addr);

  // Restore stdout to display the balance
  process.stdout.write = originalStdoutWrite;
  
  process.stdout.write(balance.toString());  // Output balance
  
  // Disconnect from the node after querying
  await api.disconnect();
}

// Get the URL and accountId passed as arguments (argv[2] for URL, argv[3] for account ID)
const nodeUrl = process.argv[2];
const accountId = process.argv[3];

if (nodeUrl && accountId) {
  getBalance(nodeUrl, accountId).catch(console.error);
} else {
  console.error("Both URL and Account ID are required.");
}

