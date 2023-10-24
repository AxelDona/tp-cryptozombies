// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ownable.sol";

contract ZombieFactory is Ownable{

    event NewZombie(uint zombieId, string name, uint dna);

    uint dnaDigits = 16;
    uint dnaModulus = 10 ** dnaDigits;
    uint cooldownTime = 1 days;

    struct Zombie{
        string name;
        uint dna;
        uint32 level;
        uint32 readyTime;
    }

    Zombie[] public zombies;

    function createZombie(string memory _name, uint _dna) internal {
        uint id = zombies.length;
        zombies.push(Zombie(_name, _dna, 1, uint32(block.timestamp + cooldownTime)));
        emit NewZombie(id, _name, _dna);
        zombieToOwner[id] = msg.sender;
        ownerZombieCount[msg.sender] ++;
    }

    function _generateRandomDna(string memory _str) private view returns (uint){
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createRandomZombie(string memory _name) public{
        require(ownerZombieCount[msg.sender] == 0);
        uint randDna = _generateRandomDna(_name);
        createZombie(_name, randDna);
    }

    mapping (uint => address) public zombieToOwner;
    mapping (address => uint) public ownerZombieCount;
}