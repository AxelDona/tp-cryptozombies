// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "src/zombieownership.sol";

contract CryptozombiesTest is Test {
    function setUp() public {}

    receive() external payable {}

    function testLesson1Chapter2() public {
        ZombieFactory zombieFactory = new ZombieFactory();
        assertTrue(address(zombieFactory) != address(0));
    }

    function testLesson1Chapter3() public {
        ZombieFactory zombieFactory = new ZombieFactory();
        assertEq(
            vm.load(address(zombieFactory), bytes32(uint(1))),
            bytes32(uint(16))
        );
    }

    function testLesson1Chapter4() public {
        ZombieFactory zombieFactory = new ZombieFactory();
        assertEq(
            vm.load(address(zombieFactory), bytes32(uint(2))),
            bytes32(uint(10 ** 16))
        );
    }

    function testLesson1Chapter6() public {
        ZombieFactory zombieFactory = new ZombieFactory();
        vm.expectRevert();
        zombieFactory.zombies(0); // This should compile but revert because the array is empty
    }

    function testLesson1Chapter12() public {
        ZombieFactory zombieFactory = new ZombieFactory();
        zombieFactory.createRandomZombie("Zombie 2600");
        (string memory name, uint dna, , , , ) = zombieFactory.zombies(0);
        assertEq(name, "Zombie 2600");
        assertEq(
            dna,
            uint(keccak256(abi.encodePacked("Zombie 2600"))) % (10 ** 16)
        );

        vm.prank(address(42));
        zombieFactory.createRandomZombie("Bizon");
        (name, dna, , , , ) = zombieFactory.zombies(1);
        assertEq(name, "Bizon");
        assertEq(dna, uint(keccak256(abi.encodePacked("Bizon"))) % (10 ** 16));
    }

    event NewZombie(uint zombieId, string name, uint dna);

    function testLesson1Chapter13() public {
        ZombieFactory zombieFactory = new ZombieFactory();
        vm.expectEmit(true, true, true, true, address(zombieFactory));
        emit NewZombie(
            0,
            "Zombie 2600",
            uint(keccak256(abi.encodePacked("Zombie 2600"))) % (10 ** 16)
        );
        zombieFactory.createRandomZombie("Zombie 2600");

        vm.expectEmit(true, true, true, true, address(zombieFactory));
        emit NewZombie(
            1,
            "Bizon",
            uint(keccak256(abi.encodePacked("Bizon"))) % (10 ** 16)
        );
        vm.prank(address(42));
        zombieFactory.createRandomZombie("Bizon");
    }

    function testLesson2Chapter2() public {
        ZombieFactory zombieFactory = new ZombieFactory();
        assertEq(zombieFactory.zombieToOwner(0), address(0));
    }

    function testLesson2Chapter3() public {
        ZombieFactory zombieFactory = new ZombieFactory();
        zombieFactory.createRandomZombie("Zombie 2600");
        assertEq(zombieFactory.zombieToOwner(0), address(this));

        // Check zombie count:
        assertEq(
            uint(
                vm.load(
                    address(zombieFactory),
                    bytes32(
                        uint(
                            keccak256(
                                abi.encode(address(this), 6) // 6 is the slot of ownerZombieCount in ZombieFactory, and we are looking for address(this) key
                            )
                        )
                    )
                )
            ),
            1
        );

        vm.prank(address(42));
        zombieFactory.createRandomZombie("Bizon");
        assertEq(zombieFactory.zombieToOwner(1), address(42));

        // Check zombie count:
        assertEq(
            uint(
                vm.load(
                    address(zombieFactory),
                    bytes32(
                        uint(
                            keccak256(
                                abi.encode(address(42), 6) // 6 is the slot of ownerZombieCount in ZombieFactory, and we are looking for address(42) key
                            )
                        )
                    )
                )
            ),
            1
        );
    }

    function testLesson2Chapter4() public {
        ZombieFactory zombieFactory = new ZombieFactory();
        zombieFactory.createRandomZombie("Zombie 2600");
        // Only 1 zombie per address:
        vm.expectRevert();
        zombieFactory.createRandomZombie("Zombie 2600 2");

        vm.prank(address(42));
        zombieFactory.createRandomZombie("Bizon");

        // Only 1 zombie per address:
        vm.prank(address(42));
        vm.expectRevert();
        zombieFactory.createRandomZombie("Bizon 2");
    }

    function testLesson2Chapter5() public {
        ZombieFeeding zombieFeeding = new ZombieFeeding();
        assertTrue(address(zombieFeeding) != address(0));
    }

    function testLesson2Chapter10() public {
        KittyInterface kitty = new FakeKitty();
        (
            bool isGestating,
            bool isReady,
            uint256 cooldownIndex,
            uint256 nextActionAt,
            uint256 siringWithId,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 generation,
            uint256 genes
        ) = kitty.getKitty(42);
        assertEq(isGestating, false);
        assertEq(isReady, true);
        assertEq(cooldownIndex, 1);
        assertEq(nextActionAt, 2);
        assertEq(siringWithId, 3);
        assertEq(birthTime, 4);
        assertEq(matronId, 5);
        assertEq(sireId, 6);
        assertEq(generation, 7);
        assertEq(genes, 42);
    }

    function testLesson2Chapter12() public {
        ZombieFeeding zombieFeeding = new ZombieFeeding();
        zombieFeeding.setKittyContractAddress(
            0x06012c8cf97BEaD5deAe237070F9587f8E7A266d
        );
        zombieFeeding.createRandomZombie("Zombie 2600");

        uint kittyGene = uint(keccak256("KittyGene"));

        vm.mockCall(
            address(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d),
            abi.encodeWithSelector(KittyInterface.getKitty.selector, 42),
            abi.encode(false, false, 0, 0, 0, 0, 0, 0, 0, kittyGene)
        );

        vm.warp(block.timestamp + 1 days);
        zombieFeeding.feedOnKitty(0, 42);

        (, uint dna, , , , ) = zombieFeeding.zombies(0);
        (string memory name2, uint dna2, , , , ) = zombieFeeding.zombies(1);

        uint expectedNonKittyDna = ((dna + (kittyGene % 10 ** 16)) / 2);
        uint expectedKittyDna = expectedNonKittyDna -
            (expectedNonKittyDna % 100) +
            99;

        assertEq(name2, "NoName");
        assertEq(dna2, expectedKittyDna);
    }

    function testLesson2Chapter13() public {
        ZombieFeeding zombieFeeding = new ZombieFeeding();
        zombieFeeding.setKittyContractAddress(
            0x06012c8cf97BEaD5deAe237070F9587f8E7A266d
        );
        zombieFeeding.createRandomZombie("Zombie 2600");

        uint kittyGene = uint(keccak256("KittyGene"));

        vm.mockCall(
            address(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d),
            abi.encodeWithSelector(KittyInterface.getKitty.selector, 42),
            abi.encode(false, false, 0, 0, 0, 0, 0, 0, 0, kittyGene)
        );

        vm.warp(block.timestamp + 1 days);
        zombieFeeding.feedOnKitty(0, 42);
        (, uint dna2, , , , ) = zombieFeeding.zombies(1);
        assertEq(dna2 % 100, 99);
    }

    function testLesson3Chapter1() public {
        ZombieFeeding zombieFeeding = new ZombieFeeding();
        zombieFeeding.createRandomZombie("Zombie 2600");
        zombieFeeding.setKittyContractAddress(
            0x06012c8cf97BEaD5deAe237070F9587f8E7A266d
        );
        assertEq32(
            vm.load(address(zombieFeeding), bytes32(uint(7))),
            bytes32(abi.encode(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d))
        );
    }

    function testLesson3Chapter2() public {
        ZombieFeeding zombieFeeding = new ZombieFeeding();
        assertEq(zombieFeeding.owner(), address(this));
    }

    function testLesson3Chapter3() public {
        ZombieFeeding zombieFeeding = new ZombieFeeding();

        vm.prank(address(42));
        vm.expectRevert();
        zombieFeeding.setKittyContractAddress(
            0x06012c8cf97BEaD5deAe237070F9587f8E7A266d
        );
    }

    function testLesson3Chapter5() public {
        ZombieFeeding zombieFeeding = new ZombieFeeding();
        assertEq(
            uint(vm.load(address(zombieFeeding), bytes32(uint(3)))),
            1 days
        );
        zombieFeeding.createRandomZombie("Zombie 2600");
        (, , uint32 level, uint32 readyTime, , ) = zombieFeeding.zombies(0);
        assertEq(level, 1);
        assertEq(readyTime, block.timestamp + 1 days);
    }

    function testLesson3Chapter7() public {
        ZombieFeeding zombieFeeding = new ZombieFeeding();
        zombieFeeding.setKittyContractAddress(
            0x06012c8cf97BEaD5deAe237070F9587f8E7A266d
        );
        zombieFeeding.createRandomZombie("Zombie 2600");

        uint kittyGene = uint(keccak256("KittyGene"));

        vm.mockCall(
            address(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d),
            abi.encodeWithSelector(KittyInterface.getKitty.selector, 42),
            abi.encode(false, false, 0, 0, 0, 0, 0, 0, 0, kittyGene)
        );

        vm.expectRevert(); // We expect revert when feeding before the cooldown
        zombieFeeding.feedOnKitty(0, 42);

        (, , , uint readyTime, , ) = zombieFeeding.zombies(0);
        assertEq(readyTime, block.timestamp + 1 days);

        // We can feed after the cooldown:
        vm.warp(block.timestamp + 1 days);
        zombieFeeding.feedOnKitty(0, 42);
        (, , , readyTime, , ) = zombieFeeding.zombies(0);
        assertEq(readyTime, block.timestamp + 1 days);
    }

    function testLesson3Chapter8() public {
        ZombieHelper zombieHelper = new ZombieHelper();
        assertTrue(address(zombieHelper) != address(0));
    }

    function testLesson3Chapter9() public {
        ZombieHelper zombieHelper = new ZombieHelper();
        zombieHelper.createRandomZombie("Zombie 2600");

        vm.expectRevert(); // Need level 2
        zombieHelper.changeName(0, "Zombie 2001");

        uint zombieArraySlot = 4;
        uint levelAndReadyTimeSlot = uint(
            keccak256(abi.encode(zombieArraySlot))
        ) + 2; // level and readyTime are store in slot 2
        uint levelAndReadyTime = uint(
            vm.load(address(zombieHelper), bytes32(uint(levelAndReadyTimeSlot)))
        );
        uint readyTime = uint32(levelAndReadyTime >> 32); // Unpack readyTime from uint256

        vm.store(
            address(zombieHelper),
            bytes32(uint(levelAndReadyTimeSlot)),
            bytes32((readyTime << 32) | 2)
        ); // Should be level 2 now

        (, , uint newLevel, uint newReadyTime, , ) = zombieHelper.zombies(0);

        assertEq(newReadyTime, readyTime);
        assertEq(newLevel, 2);

        zombieHelper.changeName(0, "Zombie 2001");
        (string memory name, , , , , ) = zombieHelper.zombies(0);
        assertEq(name, "Zombie 2001");

        vm.expectRevert(); // Need level 20
        zombieHelper.changeDna(0, 42);

        vm.store(
            address(zombieHelper),
            bytes32(uint(levelAndReadyTimeSlot)),
            bytes32((readyTime << 32) | 20)
        ); // Should be level 20 now

        (, , newLevel, newReadyTime, , ) = zombieHelper.zombies(0);

        assertEq(newReadyTime, readyTime);
        assertEq(newLevel, 20);

        zombieHelper.changeDna(0, 42);
        (, uint dna, , , , ) = zombieHelper.zombies(0);
        assertEq(dna, 42);
    }

    function testLesson3Chapter10() public {
        ZombieHelper zombieHelper = new ZombieHelper();
        zombieHelper.createRandomZombie("Zombie 2600");

        vm.prank(address(42));
        zombieHelper.createRandomZombie("Bizon");

        zombieHelper.setKittyContractAddress(
            0x06012c8cf97BEaD5deAe237070F9587f8E7A266d
        );
        vm.mockCall(
            address(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d),
            abi.encodeWithSelector(KittyInterface.getKitty.selector, 42),
            abi.encode(
                false,
                false,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                uint(keccak256("KittyGene"))
            )
        );

        vm.warp(block.timestamp + 1 days);
        zombieHelper.feedOnKitty(0, 42);

        uint[] memory myZombies = zombieHelper.getZombiesByOwner(address(this));
        uint[] memory zombieOf42 = zombieHelper.getZombiesByOwner(address(42));

        uint[] memory expected = new uint[](2);
        expected[0] = 0;
        expected[1] = 2;

        assertEq(myZombies, expected);

        expected = new uint[](1);
        expected[0] = 1;
        assertEq(zombieOf42, expected);
    }

    function testLesson4Chapter1() public {
        ZombieHelper zombieHelper = new ZombieHelper();
        zombieHelper.createRandomZombie("Zombie 2600");

        vm.expectRevert();
        zombieHelper.levelUp{value: 5 ether}(0);

        vm.expectRevert();
        zombieHelper.levelUp{value: 0.0001 ether}(0);

        zombieHelper.levelUp{value: 0.001 ether}(0);

        (, , uint level, , , ) = zombieHelper.zombies(0);
        assertEq(level, 2);
    }

    function testLesson4Chapter2() public {
        ZombieHelper zombieHelper = new ZombieHelper();
        zombieHelper.createRandomZombie("Zombie 2600");
        zombieHelper.levelUp{value: 0.001 ether}(0);

        zombieHelper.setLevelUpFee(0.02 ether);

        vm.expectRevert();
        zombieHelper.levelUp{value: 0.001 ether}(0);

        zombieHelper.levelUp{value: 0.02 ether}(0);

        zombieHelper.withdraw();
        assertEq(address(zombieHelper).balance, 0);

        vm.startPrank(address(42));

        vm.expectRevert();
        zombieHelper.setLevelUpFee(0.01 ether);

        vm.expectRevert();
        zombieHelper.withdraw();
    }

    function testLesson4Chapter8() public {
        ZombieAttack zombieAttack = new ZombieAttack();
        assertEq(uint(vm.load(address(zombieAttack), bytes32(uint(10)))), 70);

        zombieAttack.createRandomZombie("Zombie 2600");
        vm.prank(address(42));
        zombieAttack.createRandomZombie("Zombie Enemy");

        assertEq(uint(vm.load(address(zombieAttack), bytes32(uint(9)))), 0);

        vm.warp(block.timestamp + 1 days);
        zombieAttack.attack(0, 1);

        assertEq(uint(vm.load(address(zombieAttack), bytes32(uint(9)))), 1);

        vm.prank(address(42));
        vm.expectRevert();
        zombieAttack.attack(0, 1);
    }

    function testLesson4Chapter9() public {
        ZombieAttack zombieAttack = new ZombieAttack();
        zombieAttack.createRandomZombie("Zombie 2600");

        (, , , , uint16 winCount, uint16 lossCount) = zombieAttack.zombies(0);
        assertEq(winCount, 0);
        assertEq(lossCount, 0);
    }

    function testLesson4Chapter11() public {
        ZombieAttack zombieAttack = new ZombieAttack();

        zombieAttack.createRandomZombie("Zombie 2600");
        vm.prank(address(42));
        zombieAttack.createRandomZombie("Zombie Enemy");

        vm.warp(block.timestamp + 1 days);
        vm.store(address(zombieAttack), bytes32(uint(10)), bytes32(uint(100))); // Forces a win

        (, , uint32 level, , uint16 winCount, uint16 lossCount) = zombieAttack
            .zombies(0);

        (, , , , uint16 winCount2, uint16 lossCount2) = zombieAttack.zombies(1);

        zombieAttack.attack(0, 1);

        (
            ,
            uint dna,
            uint32 levelAfter,
            uint32 readyTimeAfter,
            uint16 winCountAfter,
            uint16 lossCountAfter
        ) = zombieAttack.zombies(0);
        assertEq(levelAfter, level + 1);
        assertEq(readyTimeAfter, block.timestamp + 1 days);
        assertEq(winCountAfter, winCount + 1);
        assertEq(lossCountAfter, lossCount);

        (
            ,
            uint enemyDna,
            ,
            ,
            uint16 winCount2After,
            uint16 lossCount2After
        ) = zombieAttack.zombies(1);

        assertEq(winCount2After, winCount2);
        assertEq(lossCount2After, lossCount2 + 1);

        vm.warp(block.timestamp + 1 days);
        vm.store(address(zombieAttack), bytes32(uint(10)), bytes32(uint(0))); // Forces a loose

        (, , level, , winCount, lossCount) = zombieAttack.zombies(0);

        (, , , , winCount2, lossCount2) = zombieAttack.zombies(1);

        zombieAttack.attack(0, 1);

        (
            ,
            ,
            levelAfter,
            readyTimeAfter,
            winCountAfter,
            lossCountAfter
        ) = zombieAttack.zombies(0);
        assertEq(levelAfter, level);
        assertEq(readyTimeAfter, block.timestamp + 1 days);
        assertEq(winCountAfter, winCount);
        assertEq(lossCountAfter, lossCount + 1);

        (, , , , winCount2After, lossCount2After) = zombieAttack.zombies(1);

        assertEq(winCount2After, winCount2 + 1);
        assertEq(lossCount2After, lossCount2);

        (string memory name, uint newDna, , , , ) = zombieAttack.zombies(2);
        assertEq(name, "NoName");
        assertEq(newDna, (dna + enemyDna) / 2);
    }

    function testLesson5Chapter3() public {
        ZombieOwnership zombieOwnership = new ZombieOwnership();

        assertEq(zombieOwnership.balanceOf(address(this)), 0);

        zombieOwnership.createRandomZombie("Zombie 2600");

        assertEq(zombieOwnership.balanceOf(address(this)), 1);
        assertEq(zombieOwnership.ownerOf(0), address(this));
    }

    function testLesson5Chapter8() public {
        ZombieOwnership zombieOwnership = new ZombieOwnership();
        zombieOwnership.createRandomZombie("Zombie 2600");

        {
            vm.startPrank(address(42));

            vm.expectRevert();
            zombieOwnership.approve(address(42), 0);

            vm.expectRevert();
            zombieOwnership.transferFrom(address(this), address(42), 0);

            vm.stopPrank();
        }

        zombieOwnership.transferFrom(address(this), address(42), 0);
        assertEq(zombieOwnership.balanceOf(address(this)), 0);
        assertEq(zombieOwnership.balanceOf(address(42)), 1);
        assertEq(zombieOwnership.ownerOf(0), address(42));

        vm.prank(address(42));
        zombieOwnership.approve(address(this), 0);

        zombieOwnership.transferFrom(address(42), address(this), 0);
        assertEq(zombieOwnership.balanceOf(address(this)), 1);
        assertEq(zombieOwnership.balanceOf(address(42)), 0);
        assertEq(zombieOwnership.ownerOf(0), address(this));
    }
}

contract FakeKitty is KittyInterface {
    function getKitty(
        uint256 _id
    )
        external
        pure
        returns (
            bool isGestating,
            bool isReady,
            uint256 cooldownIndex,
            uint256 nextActionAt,
            uint256 siringWithId,
            uint256 birthTime,
            uint256 matronId,
            uint256 sireId,
            uint256 generation,
            uint256 genes
        )
    {
        isGestating = false;
        isReady = true;
        cooldownIndex = 1;
        nextActionAt = 2;
        siringWithId = 3;
        birthTime = 4;
        matronId = 5;
        sireId = 6;
        generation = 7;
        genes = _id;
    }
}
