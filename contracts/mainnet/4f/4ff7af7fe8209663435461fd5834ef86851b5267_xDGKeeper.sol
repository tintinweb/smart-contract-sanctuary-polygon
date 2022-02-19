// SPDX-License-Identifier: -- DG --

pragma solidity ^0.8.9;

import "./MerkleProof.sol";
import "./SafeTransfer.sol";

/**
  * @title Smart xDG Keeper
  * @author Vitally Marinchenko
  */

contract xDGKeeper is SafeTransfer {

    address public constant distributionToken = address(
        0xc6480Da81151B2277761024599E8Db2Ad4C388C8
    );

    uint256 public maximumDrop;
    uint256 public dropCount;

    uint256 public totalRequired;
    uint256 public totalCollected;

    address public masterAccount;

    struct Keeper {
        bytes32 root;
        uint256 total;
        uint256 claimed;
    }

    mapping(address => bool) public dropsWorkers;
    mapping(address => bool) public claimWorkers;

    mapping(uint256 => string) public ipfsData;
    mapping(bytes32 => Keeper) public drops;

    mapping(bytes32 => mapping(address => bool)) public hasClaimed;

    modifier onlyMaster() {
        require(
            msg.sender == masterAccount,
            "xDGKeeper: INVALID_MASTER"
        );
        _;
    }

    modifier onlyDropsWorker() {
        require(
            dropsWorkers[msg.sender] == true,
            "xDGKeeper: INVALID_DROPS_WORKRER"
        );
        _;
    }

    modifier onlyClaimWorker() {
        require(
            claimWorkers[msg.sender] == true,
            "xDGKeeper: INVALID_CLAIM_WORKER"
        );
        _;
    }

    event Withdraw(
        address indexed account,
        uint256 amount
    );

    event NewDrop(
        bytes32 indexed hash,
        address indexed master,
        string indexed ipfsAddress,
        uint256 total
    );

    event Claimed(
        uint256 indexed index,
        address indexed account,
        uint256 amount
    );

    constructor(
        address _masterAccount,
        address _claimWorker,
        address _dropsWorker,
        uint256 _maximumDrop
    ) {
        masterAccount = _masterAccount;

        claimWorkers[_claimWorker] = true;
        dropsWorkers[_dropsWorker] = true;

        maximumDrop = _maximumDrop;
    }

    function changeMaximumDrop(
        uint256 _newMaximumDrop
    )
        external
        onlyMaster
    {
        maximumDrop = _newMaximumDrop;
    }

    function createDrop(
        bytes32 _root,
        uint256 _total,
        string calldata _ipfsAddress
    )
        external
        onlyDropsWorker
    {
        require(
            _total > 0,
            "xDGKeeper: INVALID_TOTAL"
        );

        bytes32 hash = getHash(
            _ipfsAddress
        );

        require(
            drops[hash].total == 0,
            "xDGKeeper: ALREADY_CREATED"
        );

        drops[hash] = Keeper({
            root: _root,
            total: _total,
            claimed: 0
        });

        dropCount =
        dropCount + 1;

        ipfsData[dropCount] = _ipfsAddress;

        totalRequired =
        totalRequired + _total;

        emit NewDrop(
            _root,
            masterAccount,
            _ipfsAddress,
            _total
        );
    }

    function getHash(
        string calldata _ipfsAddress
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _ipfsAddress
            )
        );
    }

    function isClaimed(
        bytes32 _hash,
        address _account
    )
        public
        view
        returns (bool)
    {
        return hasClaimed[_hash][_account];
    }

    function getClaim(
        bytes32 _hash,
        uint256 _index,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    )
        external
    {
        _doClaim(
            _hash,
            _index,
            _amount,
            msg.sender,
            _merkleProof
        );
    }

    function getClaimBulk(
        bytes32[] calldata _hash,
        uint256[] calldata _index,
        uint256[] calldata _amount,
        bytes32[][] calldata _merkleProof
    )
        external
    {
        for (uint256 i = 0; i < _hash.length; i++) {
            _doClaim(
                _hash[i],
                _index[i],
                _amount[i],
                msg.sender,
                _merkleProof[i]
            );
        }
    }

    function giveClaim(
        bytes32 _hash,
        uint256 _index,
        uint256 _amount,
        address _account,
        bytes32[] calldata _merkleProof
    )
        external
        onlyClaimWorker
    {
        _doClaim(
            _hash,
            _index,
            _amount,
            _account,
            _merkleProof
        );
    }

    function giveClaimBulk(
        bytes32[] calldata _hash,
        uint256[] calldata _index,
        uint256[] calldata _amount,
        address[] calldata _account,
        bytes32[][] calldata _merkleProof
    )
        external
        onlyClaimWorker
    {
        for (uint256 i = 0; i < _hash.length; i++) {
            _doClaim(
                _hash[i],
                _index[i],
                _amount[i],
                _account[i],
                _merkleProof[i]
            );
        }
    }

    function _doClaim(
        bytes32 _hash,
        uint256 _index,
        uint256 _amount,
        address _account,
        bytes32[] calldata _merkleProof
    )
        private
    {
        require(
            isClaimed(_hash, _account) == false,
            "xDGKeeper: ALREADY_CLAIMED"
        );

        require(
            _amount <= maximumDrop,
            "xDGKeeper: INVALID_AMOUNT"
        );

        bytes32 node = keccak256(
            abi.encodePacked(
                _index,
                _account,
                _amount
            )
        );

        require(
            MerkleProof.verify(
                _merkleProof,
                drops[_hash].root,
                node
            ),
            "xDGKeeper: INVALID_PROOF"
        );

        drops[_hash].claimed =
        drops[_hash].claimed + _amount;

        totalCollected =
        totalCollected + _amount;

        require(
            drops[_hash].total >=
            drops[_hash].claimed,
            "xDGKeeper: CLAIM_EXCESS"
        );

        _setClaimed(
            _hash,
            _account
        );

        safeTransfer(
            distributionToken,
            _account,
            _amount
        );

        emit Claimed(
            _index,
            _account,
            _amount
        );
    }

    function _setClaimed(
        bytes32 _hash,
        address _account
    )
        private
    {
        hasClaimed[_hash][_account] = true;
    }

    function withdrawFunds(
        uint256 _amount
    )
        external
        onlyMaster
    {
        safeTransfer(
            distributionToken,
            masterAccount,
            _amount
        );

        emit Withdraw(
            masterAccount,
            _amount
        );
    }

    function changeMaster(
        address _newMaster
    )
        external
        onlyMaster
    {
        masterAccount = _newMaster;
    }

    function changeClaimWorker(
        address _claimWorker,
        bool _isWorker
    )
        external
        onlyMaster
    {
        claimWorkers[_claimWorker] = _isWorker;
    }

    function changeDropsWorker(
        address _dropsWorker,
        bool _isWorker
    )
        external
        onlyMaster
    {
        dropsWorkers[_dropsWorker] = _isWorker;
    }

    function getBalance()
        public
        view
        returns (uint256)
    {
        return IERC20(distributionToken).balanceOf(
            address(this)
        );
    }

    function showRemaining(
        bytes32 _hash
    )
        public
        view
        returns (uint256)
    {
        return drops[_hash].total - drops[_hash].claimed;
    }

    function showExcess(
        bytes32 _hash
    )
        external
        view
        returns (int256)
    {
        return int256(getBalance()) - int256(showRemaining(_hash));
    }

    function showRemaining()
        public
        view
        returns (uint256)
    {
        return totalRequired - totalCollected;
    }

    function showExcess()
        external
        view
        returns (int256)
    {
        return int256(getBalance()) - int256(showRemaining());
    }
}