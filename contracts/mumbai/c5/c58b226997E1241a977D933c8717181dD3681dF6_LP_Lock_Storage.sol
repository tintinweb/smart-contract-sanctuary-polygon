// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface LP {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface Token {
    function name() external view returns (string memory);
}

contract LP_Lock_Storage is Ownable {
    address public burnContract;

    mapping(address => bool) public MainDeployers;
    uint256 public lockerIDCount;

    struct SearchHelperStruct {
        address lpAddress;
        address token0Addr;
        address token1Addr;
        uint256 countID;
    }

    struct DxLockerLP {
        uint256 createdOn;
        address lockOwner;
        address lockedLPTokens;
        uint256 lockTime;
        address lpLockContract;
        bool locked;
        string logo;
        uint256 lockedAmount;
        uint256 countID;
        bool exists;
        address token0Addr;
        address token1Addr;
    }

    mapping(address => mapping(uint256 => DxLockerLP)) public DxLock4D;
    mapping(address => mapping(uint256 => SearchHelperStruct))
        public Token0Store;
    mapping(address => mapping(uint256 => SearchHelperStruct))
        public Token1Store;
    mapping(address => uint256) public Token0LPLockerCount;
    mapping(address => uint256) public Token1LPLockerCount;

    mapping(string => mapping(uint256 => SearchHelperStruct))
        public TokenNameStorage;
    mapping(string => uint256) public TokenNameCount;

    mapping(address => mapping(uint256 => SearchHelperStruct))
        public LPStoreByCreator;
    mapping(address => uint256) public UserLockerCount; //by creator of LP Locker
    mapping(address => uint256) public LPLockerCount;
    mapping(address => bool) public LPLockContracts;
    mapping(uint256 => DxLockerLP) public AllLockRecord;

    constructor(address _dao) {
        MainDeployers[msg.sender] = true;
        burnContract = _dao;
    }

    function changeDeployerState(address _account, bool _state)
        external
        onlyOwner
    {
        MainDeployers[_account] = _state;
    }

    function getPersonalLockerCount(address _owner)
        public
        view
        returns (uint256 _count)
    {
        return UserLockerCount[_owner];
    }

    function addNewLock(
        address _lpAddress,
        uint256 _locktime,
        address _lockContract,
        uint256 _tokenAmount,
        string memory _logo
    ) public {
        require(MainDeployers[msg.sender], "You are not yet a Deployer");

        address token0 = LP(_lpAddress).token0();
        address token1 = LP(_lpAddress).token1();

        DxLockerLP memory LockData = DxLockerLP({
            createdOn: block.timestamp,
            lockOwner: tx.origin,
            lockedLPTokens: _lpAddress,
            lockTime: _locktime,
            lpLockContract: _lockContract,
            locked: true,
            logo: _logo,
            lockedAmount: _tokenAmount,
            countID: LPLockerCount[_lpAddress],
            exists: true,
            token0Addr: token0,
            token1Addr: token1
        });

        SearchHelperStruct memory TokenData = SearchHelperStruct({
            lpAddress: _lpAddress,
            token0Addr: token0,
            token1Addr: token1,
            countID: LPLockerCount[_lpAddress]
        });

        DxLock4D[_lpAddress][LPLockerCount[_lpAddress]] = LockData;
        LPLockerCount[_lpAddress]++;

        string memory token0Name = _toLower(Token(token0).name());
        string memory token1Name = _toLower(Token(token1).name());

        Token0Store[token0][Token0LPLockerCount[token0]] = TokenData;
        Token1Store[token1][Token1LPLockerCount[token1]] = TokenData;

        TokenNameStorage[token0Name][TokenNameCount[token0Name]] = TokenData;
        TokenNameCount[token0Name]++;
        TokenNameStorage[token1Name][TokenNameCount[token1Name]] = TokenData;
        TokenNameCount[token1Name]++;

        LPStoreByCreator[tx.origin][UserLockerCount[tx.origin]] = TokenData;
        UserLockerCount[tx.origin]++;

        Token0LPLockerCount[token0]++;
        Token1LPLockerCount[token1]++;
        AllLockRecord[lockerIDCount] = LockData;
        lockerIDCount++;

        LPLockContracts[_lockContract] = true;
    }

    function extendLockerTime(uint256 _newLockTime, uint256 _userLockerNumber)
        public
    {
        require(LPLockContracts[msg.sender], "Not Locker Owner");
        DxLock4D[LPStoreByCreator[tx.origin][_userLockerNumber].lpAddress][
            LPStoreByCreator[tx.origin][_userLockerNumber].countID
        ].lockTime = _newLockTime;
    }

    function transferLocker(address _newOwner, uint256 _userLockerNumber)
        public
    {
        require(LPLockContracts[msg.sender], "Not Locker Owner");

        LPStoreByCreator[_newOwner][
            UserLockerCount[_newOwner]
        ] = LPStoreByCreator[tx.origin][_userLockerNumber];
        DxLock4D[LPStoreByCreator[tx.origin][_userLockerNumber].lpAddress][
            LPStoreByCreator[tx.origin][_userLockerNumber].countID
        ].lockOwner = _newOwner;
        UserLockerCount[_newOwner]++;
    }

    function unlockLocker(uint256 _userLockerNumber) public {
        require(LPLockContracts[msg.sender], "Not Locker Owner");

        DxLock4D[LPStoreByCreator[tx.origin][_userLockerNumber].lpAddress][
            LPStoreByCreator[tx.origin][_userLockerNumber].countID
        ].locked = false;
    }

    function changeLogo(string memory _newLogo, uint256 _userLockerNumber)
        public
    {
        require(LPLockContracts[msg.sender], "Not Locker Owner");
        DxLock4D[LPStoreByCreator[tx.origin][_userLockerNumber].lpAddress][
            LPStoreByCreator[tx.origin][_userLockerNumber].countID
        ].logo = _newLogo;
    }

    function getBurnContractAddress() public view returns (address) {
        return burnContract;
    }

    function setBurnContract(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Can't make it to 0");

        burnContract = _newAddress;
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    receive() external payable {
        revert();
    }
}