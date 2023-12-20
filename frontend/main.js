import "./style.css";
import {createPublicClient, http, getContract, formatUnits, createWalletClient, custom, parseUnits} from "viem";
import { goerli } from "viem/chains";
import { UNI } from "./abi/UNI";



const publicClient = createPublicClient({
    chain: goerli,
    transport: http(),
});

const [account] = await window.ethereum.request({ method: "eth_requestAccounts" });

const walletClient = createWalletClient({
    account,
    chain: goerli,
    transport: custom(window.ethereum),
});


const blockNumber = await publicClient.getBlockNumber();

const unwatch = publicClient.watchBlockNumber(
    { onBlockNumber: blockNumber => document.querySelector("#blockNumber").innerHTML = blockNumber }
)

const uniContract = getContract({
    address: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", // UNI address
    abi: UNI,
    publicClient,
    walletClient, // additional argument here
});

const decimals = await uniContract.read.decimals();
const symbol = await uniContract.read.symbol();
const name = await uniContract.read.name();
const totalSupply = await uniContract.read.totalSupply();
const balance = formatUnits(await uniContract.read.balanceOf(["0x42290ecB516460b11D94AF194aC5ce1f89b1aa34"]), decimals);

await uniContract.write.transfer(["0x42290ecB516460b11D94AF194aC5ce1f89b1aa34", 1n]);


document.querySelector("#app").innerHTML = `
  <div>
    <p>Current block is <span id="blockNumber">${blockNumber}</span></p>
    <h1>${symbol}</h1>
    <p>Name : ${name}</p>
    <p>Address : <a href="https://goerli.etherscan.io/token/0x1f9840a85d5af5bf1d1762f925bdaddc4201f984" target="_blank">0x1f9840a85d5af5bf1d1762f925bdaddc4201f984</a></p>
    <p>Total supply : ${totalSupply}</p>
    <p>Balance of 0x42290ecB516460b11D94AF194aC5ce1f89b1aa34 : ${balance}</p>
    <hr>
    <div>
        <span>Amount : </span>
        <input type="text" id="amountInput" value="0">
        <button id="maxButton">Max</button>
    </div>
    <div>
        <span>Recipient : </span>
        <input type="text" id="recipientInput" placeholder="0x...">
        <button id="sendButton">Send</button>
    </div>
  </div>
`;

document.querySelector("#maxButton").addEventListener("click", () => {
    document.querySelector("#amountInput").value = balance;
});

document.querySelector("#sendButton").addEventListener("click", async () => {
    const amount = parseUnits(document.querySelector("#amountInput").value, decimals);
    const recipient = document.querySelector("#recipientInput").value;
    await uniContract.write.transfer([recipient, amount]);
});