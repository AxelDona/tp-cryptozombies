import "./style.css";
import {createPublicClient, http, getContract, createWalletClient, custom, parseEther} from "viem";
import { goerli } from "viem/chains";
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
            console.log(zombie)
        } catch (error) {
            break;
        }
    }
    return allZombies;
};

const updateZombiesList = async () => {
    const allZombiesData = await getAllZombies();
    allZombiesList.innerHTML = allZombiesData
        .map((zombie) => `<li class="allZombieCard"><p>${zombie[0]}</p></li>`);
};

updateZombiesList();


document.querySelector("#app").innerHTML = `
  <div>
    <span id="blockNumber">Current block is ${blockNumber}</span>
    <p>Contract owner : ${await zombieContract.read.owner()}</p>
    <p id="balance">Zombie count of <b>${await [account]}</b> : ${zombieCount}</p>
    <hr>
    <h2>Create a new zombie</h2>
    <div id="creation">
      <p>Zombie name : <input id="zombieName"></p>
      <button id="createZombie">Create</button>
    </div>
    <hr>
    <h2>My zombies</h2>
    <div class="zombieCard">
      <div class="zombieCardHeader">
       <div class="zombieCardHeaderTitle">
        <h4 >${await zombieData[0]}</h4>
        <span>Level ${await zombieData[2]}</span>
       </div>
       <button id="levelUp">Level Up!</button>
      </div>
      <ul>
        <li><strong>DNA</strong>${await zombieData[1]}</li>
        <li><strong>ReadyTime</strong>${await zombieData[3]}</li>
        <li><strong>Wins</strong>${await zombieData[4]}</li>
        <li><strong>Losses</strong>${await zombieData[5]}</li>
      </ul>
    </div>
    <hr>
    <h2>All zombies</h2>
    <div id="allZombies">
      <ul id="allZombiesList"></ul>
    </div>
  </div>
`;

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
