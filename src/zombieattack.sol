// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./zombiehelper.sol";

contract ZombieAttack is ZombieHelper {
    uint randNonce = 0;
    uint attackVictoryProbability = 70;

    function randMod(uint _modulus) internal returns (uint) {
        randNonce += 1;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
    }

    function attack(uint _zombieId, uint _targetId) external onlyOwnerOf(_zombieId) {
        Zombie storage myZombie = zombies[_zombieId];
        Zombie storage enemyZombie = zombies[_targetId];
        uint rand  = randMod(100);
        if (rand <= attackVictoryProbability) {
            myZombie.winCount += 1;
            myZombie.level += 1;
            enemyZombie.lossCount += 1;
            feedAndMultiply(_zombieId, enemyZombie.dna, "zombie");
        } else {
            enemyZombie.winCount += 1;
            myZombie.lossCount += 1;
            _triggerCooldown(myZombie);
        }
        
    }
}