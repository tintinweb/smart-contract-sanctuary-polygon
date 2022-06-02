// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
 * @dev Partial interface of the ERC20 standard.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/**
 * @dev Partial interface of the Staking contract.
 */
interface IStaking {
    function getUserDeposit (
        address userAddress, uint256 depositProfileId
    ) external view returns (
        uint256 depositIndex, uint256 amount, uint256 unlock,
        uint256 updatedAt, uint256 accumulatedYield,
        uint256 lastMarketIndex
    );
}

contract BorrowingPower {
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Caller is not the owner');
        _;
    }
    modifier onlyManager() {
        require(_managers[msg.sender], '1.1');
        _;
    }

    mapping (address => bool) internal _managers;
    // 0 - None holders of ETNA
    // 1 - Holders of ETNA
    // 2 - Bronze stakers of ETNA
    // 3 - Silver stakers of ETNA
    // 4 - Gold stakers of ETNA
    // 5 - Platinum stakers of ETNA
    uint16[6] internal _borrowingPower; // * DECIMALS (1.5 => 15000)
    uint16[] internal _bronzeStakingProfileIds; // profile ids in the staking contract that
    // belong to the bronze vault
    uint16[] internal _silverStakingProfileIds; // profile ids in the staking contract that
    // belong to the silver vault
    uint16[] internal _goldStakingProfileIds; // profile ids in the staking contract that
    // belong to the gold vault
    uint16[] internal _platinumStakingProfileIds; // profile ids in the staking contract that
    // belong to the platinum vault
    uint256 internal _minimalStake; // minimal staked amount used
    // when borrowing power is calculated
    IStaking internal _stakingContract;
    IERC20 internal _etnaContract;
    // etna token, it's balance is used for a borrowing power calculation
    address internal _owner; // contract owner

    constructor (
        address etnaContractAddress,
        address stakingContractAddress,
        uint256 minimalStake
    ) {
        require(stakingContractAddress != address(0), 'Staking contract address can not be zero');
        _stakingContract = IStaking(stakingContractAddress);
        require(etnaContractAddress != address(0), 'Etna contract address can not be zero');
        _etnaContract = IERC20(etnaContractAddress);
        _minimalStake = minimalStake;
        _owner = msg.sender;
        _managers[_owner] = true;
    }

    function setBronzeStakingProfileIds (
        uint16[] calldata stakingProfileIds
    ) external onlyManager returns (bool) {
        delete _bronzeStakingProfileIds;
        for (uint256 i = 0; i < stakingProfileIds.length; i ++) {
            _bronzeStakingProfileIds.push(stakingProfileIds[i]);
        }
        return true;
    }

    function setSilverStakingProfileIds (
        uint16[] memory stakingProfileIds
    ) external onlyManager returns (bool) {
        delete _silverStakingProfileIds;
        for (uint256 i = 0; i < stakingProfileIds.length; i ++) {
            _silverStakingProfileIds.push(stakingProfileIds[i]);
        }
        return true;
    }

    function setGoldStakingProfileIds (
        uint16[] memory stakingProfileIds
    ) external onlyManager returns (bool) {
        delete _goldStakingProfileIds;
        for (uint256 i = 0; i < stakingProfileIds.length; i ++) {
            _goldStakingProfileIds.push(stakingProfileIds[i]);
        }
        return true;
    }

    function setPlatinumStakingProfileIds (
        uint16[] memory stakingProfileIds
    ) external onlyManager returns (bool) {
        delete _platinumStakingProfileIds;
        for (uint256 i = 0; i < stakingProfileIds.length; i ++) {
            _platinumStakingProfileIds.push(stakingProfileIds[i]);
        }
        return true;
    }

    function setStakingContract (
        address stakingAddress
    ) external onlyManager returns (bool) {
        require(
            stakingAddress != address(0), 'Staking contract address can not be zero'
        );
        _stakingContract = IStaking(stakingAddress);
        return true;
    }

    function setEtnaContract (
        address etnaAddress
    ) external onlyManager returns (bool) {
        require(
            etnaAddress != address(0), 'Etna contract address can not be zero'
        );
        _etnaContract = IERC20(etnaAddress);
        return true;
    }

    function setMinimalStake (
        uint256 minimalStake
    ) external onlyManager returns (bool) {
        _minimalStake = minimalStake;
        return true;
    }

    function setBorrowingPowerData (
        uint16[] calldata borrowingPower
    ) external onlyManager returns (bool) {
        for (uint256 i = 0; i < _borrowingPower.length; i ++) {
            _borrowingPower[i] = borrowingPower[i];
        }
        return true;
    }

    // owner function
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), '8.1');
        _owner = newOwner;
        return true;
    }

    function addToManagers (
        address userAddress
    ) public onlyOwner returns (bool) {
        _managers[userAddress] = true;
        return true;
    }

    function removeFromManagers (
        address userAddress
    ) public onlyOwner returns (bool) {
        _managers[userAddress] = false;
        return true;
    }

    // view functions
    function getStakingProfileIds () external view returns (
        uint16[] memory bronzeStakingProfileIds,
        uint16[] memory silverStakingProfileIds,
        uint16[] memory goldStakingProfileIds,
        uint16[] memory platinumStakingProfileIds
    ) {
        return (
        _bronzeStakingProfileIds,
        _silverStakingProfileIds,
        _goldStakingProfileIds,
        _platinumStakingProfileIds
        );
    }

    function getUserBorrowingPower (
        address userAddress
    ) external view returns (uint256) {
        uint256 stake;
        for (uint256 i = 0; i < _platinumStakingProfileIds.length; i ++) {
            (,stake,,,,) = _stakingContract.getUserDeposit(
                userAddress, _platinumStakingProfileIds[i]
            );
            if (stake >= _minimalStake) {
                return _borrowingPower[5];
            }
        }
        for (uint256 i = 0; i < _goldStakingProfileIds.length; i ++) {
            (,stake,,,,) = _stakingContract.getUserDeposit(
                userAddress, _goldStakingProfileIds[i]
            );
            if (stake >= _minimalStake) {
                return _borrowingPower[4];
            }
        }
        for (uint256 i = 0; i < _silverStakingProfileIds.length; i ++) {
            (,stake,,,,) = _stakingContract.getUserDeposit(
                userAddress, _silverStakingProfileIds[i]
            );
            if (stake >= _minimalStake) {
                return _borrowingPower[3];
            }
        }
        for (uint256 i = 0; i < _bronzeStakingProfileIds.length; i ++) {
            (,stake,,,,) = _stakingContract.getUserDeposit(
                userAddress, _bronzeStakingProfileIds[i]
            );
            if (stake >= _minimalStake) {
                return _borrowingPower[2];
            }
        }
        if (_etnaContract.balanceOf(userAddress) > 0) return _borrowingPower[1];
        return _borrowingPower[0];
    }

    function getBorrowingPowerData () external view returns (uint16[6] memory) {
        return _borrowingPower;
    }

    function getMinimalStake () external view returns (uint256) {
        return _minimalStake;
    }

    function getContractAddresses () external view returns (
        address stakingContract,
        address etnaContract
    ) {
        return (
            address(_stakingContract),
            address(_etnaContract)
        );
    }

    /**
     * @dev If true - user has manager role
     */
    function isManager (
        address userAddress
    ) external view returns (bool) {
        return _managers[userAddress];
    }

    /**
     * @dev Owner address getter
     */
    function owner() public view returns (address) {
        return _owner;
    }
}