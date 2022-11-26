/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WalletStakeContract {
    address private admin;
    uint256 public stakeBlockRange;
    uint256 public stakePerRight;
    mapping(address => uint256) public stakeLocked;
    mapping(address => uint256) public stakeRewards;
    mapping(address => uint256) public stakeFree;
    address[] public stakeRight;
    uint256 swapTransferNonce;
    event SwapTransfer(
        bytes32 indexed fromChainHash,
        bytes32 indexed toChainHash,
        bytes32 swapPath
    );

    constructor() {
        admin = msg.sender;
        stakeBlockRange = 100;
        stakePerRight = 100 * 10**18;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function test(uint256 _stakeAmount)
        public
        view
        onlyAdmin
        returns (uint256)
    {
        uint256 rights;
        rights = _stakeAmount / stakePerRight;
        return rights;
    }

    function stakeStatus(address _stakeAddress)
        public
        view
        returns (
            uint256 _stakeLocked,
            uint256 _stakeRewards,
            uint256 _stakeFree,
            uint256 _stakePerRight,
            uint256 _stakeBlockRange
        )
    {
        _stakeLocked = stakeLocked[_stakeAddress];
        _stakeRewards = stakeRewards[_stakeAddress];
        _stakeFree = stakeFree[_stakeAddress];
        _stakePerRight = stakePerRight;
        _stakeBlockRange = stakeBlockRange;
    }

    function random(uint256 num) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        msg.sender
                    )
                )
            ) % num;
    }

    function randomWithRandomInt(uint256 _maxNum, uint256 _randomInt)
        public
        view
        returns (uint256)
    {
        uint256 seed0 = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.difficulty, msg.sender)
            )
        );
        uint256 seed1 = uint256(blockhash(block.number - _randomInt));

        return (seed0 + seed1 + _randomInt + block.number) % _maxNum;
    }

    function addSwapOrder(
        bytes32 _fromChainHash,
        bytes32 _toChainHash,
        bytes32 _swapPath,
        uint256 _comision,
        uint256 _randomInt
    ) public {
        emit SwapTransfer(_fromChainHash, _toChainHash, _swapPath);
        address winner = stakeWining(_randomInt);
        stakeRewards[winner] = stakeRewards[winner] + ((_comision * 4) / 5);
    }

    function addSwapOrdertest(uint256 _comision, uint256 _randomInt) public {
        address winner = stakeWining(_randomInt);
        stakeRewards[winner] = stakeRewards[winner] + ((_comision * 4) / 5);
    }

    function stakeWining(uint256 _randomInt) public view returns (address) {
        uint256 winnerIndex = randomWithRandomInt(
            stakeRight.length,
            _randomInt
        );
        return stakeRight[winnerIndex];
    }

    function stakeWining1(uint256 _randomInt)
        public
        view
        returns (uint256, uint256)
    {
        uint256 winnerIndex = randomWithRandomInt(
            stakeRight.length,
            _randomInt
        );
        return (winnerIndex, stakeRight.length);
    }

    // function addSwapOrder(
    //     bytes32 _fromChainHash,
    //     bytes32 _toChainHash,
    //     bytes32 _swapPath,
    //     uint256 _comision
    // ) public {
    //     emit SwapTransfer(_fromChainHash, _toChainHash, _swapPath);
    //     address winner = stakeWining();
    //     stakeRewards[winner] = stakeRewards[winner] + ((_comision * 4) / 5);
    // }

    // function addSwapOrdertest(uint256 _comision) public {
    //     address winner = stakeWining();
    //     stakeRewards[winner] = stakeRewards[winner] + ((_comision * 4) / 5);
    // }

    // function stakeWining() public view returns (address) {
    //     uint256 winnerIndex = random(stakeRight.length);
    //     return stakeRight[winnerIndex];
    // }

    // function stakeWining1() public view returns (uint256, uint256) {
    //     uint256 winnerIndex = random(stakeRight.length);
    //     return (winnerIndex, stakeRight.length);
    // }

    function addStake(uint256 _stakeAmount, address _stakeAddress) public {
        uint256 rights;
        rights = _stakeAmount / stakePerRight;
        stakeLocked[_stakeAddress] = stakeLocked[_stakeAddress] + _stakeAmount;
        for (uint256 i = 0; i < rights; i++) {
            stakeRight.push(_stakeAddress);
        }
    }

    function removeStake(uint256 index) public {
        uint256 len = stakeRight.length;
        if (index == len - 1) {
            stakeRight.pop();
        } else {
            stakeRight[index] = stakeRight[len - 1];
            stakeRight.pop();
        }
    }

    function withdrawStake() public {
        for (uint256 i = 0; i < stakeRight.length; i++) {
            if (stakeRight[i] == msg.sender) {
                removeStake(i);
            }
        }
        if (stakeRight[stakeRight.length - 1] == msg.sender) {
            stakeRight.pop();
        }
    }

    function viewRight() public view returns (address[] memory) {
        return stakeRight;
    }



    // function viewRight() public view returns (uint256) {
    //     return stakeRight[msg.sender];
    // }
}