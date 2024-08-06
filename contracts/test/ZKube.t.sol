// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ZKubeHarness} from "./ZKube.harness.sol";
import {Game, Player, Proof, Puzzle, PuzzleJson} from "../src/Types.sol";
import {ZKubePuzzleSet} from "../src/ZKubePuzzleSet.sol";
import "../src/Errors.sol";
import {ZKubeVerifier} from "../src/ZKubeVerifier.sol";
import {stdJson} from "forge-std/StdJson.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import {GameCreated, GameJoined, PlayerSubmitted, GameResolved} from "../src/Events.sol";

contract ZKubeTest is Test {
    using stdJson for string;

    ZKubeHarness public zKube;
    address public zKubeVerifier;
    address public zKubePuzzleSet;

    address public deployer = vm.addr(1);
    address public player1 = vm.addr(2);
    address public player2 = vm.addr(3);

    Proof internal proofPlayerOne;
    Proof internal proofPlayerTwo;
    Puzzle[] public puzzles;

    constructor() {
        string memory root = vm.projectRoot();
        string memory proofPathPlayerOne = string.concat(root, "/test/zkube_proof_player_one.json");
        string memory proofPathPlayerTwo = string.concat(root, "/test/zkube_proof_player_two.json");
        string memory proofJsonPlayerOne = vm.readFile(proofPathPlayerOne);
        string memory proofJsonPlayerTwo = vm.readFile(proofPathPlayerTwo);

        proofPlayerOne = parseProof(proofJsonPlayerOne);
        proofPlayerTwo = parseProof(proofJsonPlayerTwo);

        string memory puzzleFile = vm.readFile("./script/data/test.puzzles.json");
        bytes memory puzzleJson = vm.parseJson(puzzleFile);
        PuzzleJson[] memory _puzzles = abi.decode(puzzleJson, (PuzzleJson[]));
        for (uint256 i; i < _puzzles.length; i++) {
            Puzzle memory puzzle = Puzzle({
                startingGrid: bytes16(_puzzles[i].startingGrid),
                finalGrid: bytes16(_puzzles[i].finalGrid),
                availableFunctions: _puzzles[i].availableFunctions
            });
            puzzles.push(puzzle);
        }
    }

    function parseProof (string memory proofJson) public pure returns(Proof memory) {
        uint256[137] memory input;
        for (uint256 i = 0; i < input.length; i++) {
            input[i] = proofJson.readUint(string.concat(string.concat(".[3].[", Strings.toString(i)), "]"));
        }

        return Proof(
            [proofJson.readUint(".[0].[0]"), proofJson.readUint(".[0].[1]")],
            [
                [proofJson.readUint(".[1].[0].[0]"), proofJson.readUint(".[1].[0].[1]")],
                [proofJson.readUint(".[1].[1].[0]"), proofJson.readUint(".[1].[1].[1]")]
            ],
            [proofJson.readUint(".[2].[0]"), proofJson.readUint(".[2].[1]")],
            input
        );
    }

    function setUp() public {
        vm.deal(deployer, 100 ether);
        vm.deal(player1, 100 ether);
        vm.deal(player2, 100 ether);
        vm.startPrank(deployer);
        zKubeVerifier = address(new ZKubeVerifier());
        ZKubePuzzleSet puzzleSet = new ZKubePuzzleSet("Demo puzzle set", "ZKPuzzle");
        zKubePuzzleSet = address(puzzleSet);

         for (uint256 i; i < puzzles.length; i++) {
            puzzleSet.addPuzzle(puzzles[i]);
        }
        zKube = new ZKubeHarness(zKubeVerifier);
        vm.stopPrank();
    }

    function test_init() public {
        assertEq(zKube.verifier(), zKubeVerifier);
    }

    function testConcrete_createGame() public {
        uint8 interval = 10;
        uint8 numberOfTurns = 20;
        vm.expectEmit(true, true, true, true);
        emit GameCreated(1, zKubePuzzleSet, player1, interval, numberOfTurns);
        uint256 id = _createGame(player1, interval, numberOfTurns);

        (
            Player memory p1,
            Player memory p2,
            address puzzleSet,
            uint16 interval_,
            uint8 numberOfTurns_,
            uint72 startingBlock
        ) = zKube.games(id);
        assertEq(p1.address_, player1);
        assertEq(p1.score, 0);
        assertEq(p2.address_, address(0));
        assertEq(p2.score, 0);
        assertEq(interval_, interval);
        assertEq(numberOfTurns_, numberOfTurns);
        assertEq(puzzleSet, zKubePuzzleSet);
        assertEq(startingBlock, 0);
    }

    function testConcrete_joinGame() public {
        uint256 id = _createGame(player1, 10, 20);

        uint88 currentBlock = uint88(block.number);
        vm.expectEmit(true, true, true, true);
        emit GameJoined(id, player1, player2, currentBlock + zKube.BLOCKS_UNTIL_START());
        uint256 startingBlock = _joinGame(player2, id);

        (, Player memory p2,,,,) = zKube.games(id);
        assertEq(p2.address_, player2);
        assertEq(startingBlock, currentBlock + zKube.BLOCKS_UNTIL_START());
    }

    function testConcrete_joinGame_reverts_ifJoiningYourOwnGame() public {
        uint256 id = _createGame(player1, 10, 20);

        vm.prank(player1);
        vm.expectRevert(JoiningYourOwnGame.selector);
        zKube.joinGame(id);
    }

    function testConcrete_getBlock() public {
        uint16 interval = 10;
        uint8 numberOfRounds = 20;
        uint256 randomBlock = 21382132;
        vm.roll(randomBlock);
        uint256 id = _createGame(player1, interval, numberOfRounßds);

        uint256 startingBlock = _joinGame(player2, id);
        assertEq(randomBlock + zKube.BLOCKS_UNTIL_START(), startingBlock);
        vm.roll(startingBlock);
        assertEq(zKube.exposed_getBlock(interval, uint72(startingBlock), numberOfRounds), startingBlock);
        vm.roll(startingBlock + interval + 5);
        assertEq(zKube.exposed_getBlock(interval, uint72(startingBlock), numberOfRounds), startingBlock + interval);
    }

    function testFuzz_getBlock(uint256 startingBlock, uint256 jump) public {
        uint16 interval = 10;
        uint8 numberOfTurns = 20;

        vm.assume(jump < interval * numberOfTurns);
        vm.assume(startingBlock < type(uint64).max);
        vm.roll(startingBlock);
        uint256 id = _createGame(player1, interval, 20);

        _joinGame(player2, id);
        vm.roll(startingBlock + jump);

        uint256 expectedBlockNumber = block.number - ((block.number - startingBlock) % interval);

        assertEq(zKube.exposed_getBlock(interval, uint72(startingBlock), numberOfTurns), expectedBlockNumber);
        assertTrue((zKube.exposed_getBlock(interval, uint72(startingBlock), numberOfTurns) - startingBlock) % interval == 0);
    }

    function testFuzz_getBlock_reverts_ifGameFinished(uint256 jump) public {
        uint16 interval = 10;
        uint8 numberOfTurns = 20;

        uint256 id = _createGame(player1, interval, 20);

        uint256 startingBlock = _joinGame(player2, id);
        vm.roll(startingBlock);

        vm.assume(jump >= interval * numberOfTurns && jump < type(uint72).max);
        vm.roll(startingBlock + jump);

        vm.expectRevert(GameFinished.selector);
        zKube.exposed_getBlock(interval, uint72(startingBlock), numberOfTurns);
    }

    function testConcrete_submitPuzzle() public {
        uint256 id = _createGame(player1, 10, 20);

        uint256 startingBlock = _joinGame(player2, id);
        vm.roll(startingBlock);
        vm.prank(player1);
        Player memory expectedP1 = Player(player1, 1, 1);
        vm.expectEmit(true, true, true, true);
        emit PlayerSubmitted(id, expectedP1);
        zKube.submitPuzzle(id, proofPlayerOne);

        (Player memory p1,,,,,) = zKube.games(id);

        assertEq(p1.score, 1);
        assertEq(p1.totalBlocks, 1);
    }

    function testConcrete_submitPuzzle_reverts_ifInvalidProof() public {
        uint256 id = _createGame(player1, 10, 20);

        uint256 startingBlock = _joinGame(player2, id);
        vm.roll(startingBlock);

        Proof memory proof_;

        vm.prank(player1);
        vm.expectRevert(InvalidProof.selector);
        zKube.submitPuzzle(id, proof_);
    }

    function testConcrete_submitPuzzle_reverts_ifAlreadySubmitted() public {
        uint256 id = _createGame(player1, 10, 20);

        uint256 startingBlock = _joinGame(player2, id);

        vm.roll(startingBlock);

        vm.startPrank(player1);
        zKube.submitPuzzle(id, proofPlayerOne);

        vm.expectRevert(AlreadySubmitted.selector);
        zKube.submitPuzzle(id, proofPlayerOne);
    }

    function testConcrete_submitPuzzle_reverts_ifGameFinished() public {
        uint8 interval = 10;
        uint16 numberOfTurns = 20;

        uint256 id = _createGame(player1, interval, 20);

        uint256 startingBlock = _joinGame(player2, id);
        vm.roll(startingBlock + interval * numberOfTurns);

        Proof memory proof_;

        vm.expectRevert(GameFinished.selector);
        vm.prank(player1);
        zKube.submitPuzzle(id, proof_);
    }

    function testConcrete_resolveGame() external {
        uint8 interval = 10;
        uint16 numberOfRounds = 20;
        uint256 id = _createGame(player1, 10, 20);

        uint256 startingBlock = _joinGame(player2, id);
        vm.roll(startingBlock);

        vm.startPrank(player1);
        zKube.submitPuzzle(id, proofPlayerOne);

        vm.roll(startingBlock + interval * numberOfRounds);

        vm.expectEmit(true, true, true, true);
        emit GameResolved(id, player1);
        zKube.resolveGame(id);
    }

    function testConcrete_resolveGame_draw() external {
        uint8 interval = 10;
        uint16 numberOfRounds = 20;
        uint256 id = _createGame(player1, 10, 20);

        uint256 startingBlock = _joinGame(player2, id);
        vm.roll(startingBlock);

        vm.prank(player1);
        zKube.submitPuzzle(id, proofPlayerOne);

        vm.roll(block.number + interval);

        vm.prank(player2);
        zKube.submitPuzzle(id, proofPlayerTwo);

        vm.roll(block.number + interval * numberOfRounds);

        vm.expectEmit(true, true, true, true);
        emit GameResolved(id, address(0));
        zKube.resolveGame(id);
    }

    function _createGame(address player, uint16 interval, uint8 numberOfTurns) private returns (uint256 id) {
        vm.prank(player);
        id = zKube.createGame(zKubePuzzleSet, interval, numberOfTurns);
    }

    function _joinGame(address player, uint256 id) private returns (uint256 startingBlock) {
        vm.prank(player);
        zKube.joinGame(id);
        (,,,,, startingBlock) = zKube.games(id);
    }
}
