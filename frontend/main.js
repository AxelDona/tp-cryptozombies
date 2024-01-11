import "./style.css";
import {createPublicClient, http, getContract, createWalletClient, custom} from "viem";
import { goerli } from "viem/chains";
// import { UNI } from "./abi/UNI";
import { CryptoZombies } from './abi/CryptoZombies';

// Client settings

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

// UNI Transaction
/*
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
*/

// Cryptozombies


const zombieContract = getContract({
    address: "0x75D42F0C19d45d4CBd8Ce9F07885a8fB6B8FAdf6",
    abi: CryptoZombies,
    publicClient,
    walletClient,
});

const blockNumber = await publicClient.getBlockNumber();
const zombieCount = await zombieContract.read.balanceOf([account]);
const zombieData = await zombieContract.read.zombies([await zombieContract.read.getZombiesByOwner([account])]);

const getAllZombies = async () => {
    let count = 0;
    let allZombies = [];

    while (true) {
        try {
            const zombie = await zombieContract.read.zombies([count]);
            allZombies.push(zombie);
            count++;
        } catch (error) {
            break;
        }
    }
    return allZombies;
};

const updateZombiesList = async () => {
    const allZombiesData = await getAllZombies();
    allZombiesList.innerHTML = allZombiesData
        .map((zombie) => `<li class="allZombieCard">${zombie.map((data) => `<p>${data}</p>`).join('')}</li>`)
        .join('');
};

updateZombiesList();


document.querySelector("#app").innerHTML = `
  <div>
  <!--
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
    -->
    <span id="blockNumber">Current block is ${blockNumber}</span>
    <p>Contract owner : ${await zombieContract.read.owner()}</p>
    <div id="creation">
      <p>Zombie name : <input id="zombieName"></p>
      <button id="createZombie">Create</button>
    </div>
    <p id="balance">Zombie count of <b>${await [account]}</b> : ${zombieCount}</p>
    <p>My zombies :</p>
    <div id="zombieCard">
      <ul>
        ${await zombieData.map(data => `<li>${data}</li>`).join('\n')}
      </ul>
    </div>
    <button id="levelUp">Level up</button>
    <p>All zombies :</p>
    <div id="allZombies">
      <ul id="allZombiesList"></ul>
    </div>
  </div>
`;

/*
document.querySelector("#maxButton").addEventListener("click", () => {
    document.querySelector("#amountInput").value = balance;
});

document.querySelector("#sendButton").addEventListener("click", async () => {
    const amount = parseUnits(document.querySelector("#amountInput").value, decimals);
    const recipient = document.querySelector("#recipientInput").value;
    await uniContract.write.transfer([recipient, amount]);
});

 */

document.querySelector("#createZombie").addEventListener("click", async () => {
    const name = document.querySelector("#zombieName").value;

    // Check if zombieCount is greater than 0
    if (zombieCount > 0) {
        // Display a popup message
        alert("You can't have more than one zombie.");
    } else {
        // Proceed to create a new zombie if both conditions are met
        const newZombie = await zombieContract.write.createRandomZombie([name]);
    }
});

document.querySelector("#levelUp").addEventListener("click", async () => {
    // Check if the user has at least one zombie
    if (zombieCount === 0) {
        alert("You need to create a zombie first.");
        return;
    }

    try {
        // Level up the zombie by paying 0.001 ether
        const levelUpTx = await walletClient.writeContract({
            address: zombieContract.address,
            abi: CryptoZombies,
            functionName: 'levelUp',
            args: [await zombieContract.read.getZombiesByOwner([account])],
            value: parseEther('0.001')
        });

    } catch (error) {
        console.error("Error while leveling up zombie:", error);
        alert("An error occurred while leveling up the zombie. Please try again.");
    }
});
