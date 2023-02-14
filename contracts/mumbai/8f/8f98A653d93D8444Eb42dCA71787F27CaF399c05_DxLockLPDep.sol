// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

interface decentralizedStorage {
    function addNewLock(
        address _lpAddress,
        uint256 _locktime,
        address _lockContract,
        uint256 _tokenAmount,
        string memory _logo
    ) external;

    function extendLockerTime(uint256 _userLockerNumber, uint256 _newLockTime)
        external;

    function transferLocker(address _newOwner, uint256 _userLockerNumber)
        external;

    function unlockLocker(uint256 _userLockerNumber) external;

    function changeLogo(string memory _newLogo, uint256 _userLockerNumber)
        external;

    function getPersonalLockerCount(address _owner) external returns (uint256);

    function getBurnContractAddress() external view returns (address);
}

contract LaunchLPLocker is Ownable {
    string public deployer = "dx.app";
    string public deployerType = "Launchpad";
    bool public launchpad = true;
    uint256 public LockedAmount;

    uint256 public personalLockerCount;
    decentralizedStorage public storagePersonal;

    uint256 public LockExpireTimestamp;
    uint256 public LockerCreationTimestamp;

    bool public feePaid;
    uint256 public percFeeAmount;
    uint256 public RewardsNativeClaimed;
    mapping(address => uint256) public RewardsTokenClaimed;
    IERC20 public PersonalLockerToken;

    constructor(
        address _lockTokenAddress,
        uint256 _lockTimeEnd,
        uint256 _personalLockerCount,
        address _lockerStorage,
        uint256 _lockingAmount,
        uint256 _feeAmount
    ) {
        require(_lockingAmount > 0, "can't lock 0 Tokens");
        require(
            _lockTimeEnd > (block.timestamp + 600),
            "Please lock longer than now"
        );

        LockedAmount = _lockingAmount;

        PersonalLockerToken = IERC20(_lockTokenAddress);

        LockExpireTimestamp = _lockTimeEnd;
        personalLockerCount = _personalLockerCount;
        storagePersonal = decentralizedStorage(_lockerStorage);

        LockerCreationTimestamp = block.timestamp;

        feePaid = true;
        percFeeAmount = _feeAmount;

        _transferOwnership(tx.origin);
    }

    receive() external payable {}

    function changeLogo(string memory _logo) public onlyOwner {
        storagePersonal.changeLogo(_logo, personalLockerCount);
    }

    function CheckLockedBalance() public view returns (uint256) {
        return PersonalLockerToken.balanceOf(address(this));
    }

    function ExtendPersonalLocker(uint256 _newLockTime) external onlyOwner {
        require(
            LockExpireTimestamp < _newLockTime,
            "You cant reduce locktime..."
        );
        require(block.timestamp < LockExpireTimestamp, "Your Lock Expired ");

        LockExpireTimestamp = _newLockTime;
        storagePersonal.extendLockerTime(
            LockExpireTimestamp,
            personalLockerCount
        );
    }

    function transferOwnership(address _newOwner) public override onlyOwner {
        _transferOwnership(_newOwner);
        storagePersonal.transferLocker(_newOwner, personalLockerCount);
    }

    function unlockTokensAfterTimestamp() external onlyOwner {
        require(
            block.timestamp >= LockExpireTimestamp,
            "Token is still Locked"
        );
        require(feePaid, "Please pay the fee first");

        PersonalLockerToken.transfer(
            owner(),
            PersonalLockerToken.balanceOf(address(this))
        );
        storagePersonal.unlockLocker(personalLockerCount);
    }

    function unlockPercentageAfterTimestamp(uint256 _percentage)
        external
        onlyOwner
    {
        require(
            block.timestamp >= LockExpireTimestamp,
            "Token is still Locked"
        );
        require(feePaid, "Fee not paid yet");
        uint256 amountUnlock = (PersonalLockerToken.balanceOf(address(this)) *
            _percentage) / 100;
        PersonalLockerToken.transfer(owner(), amountUnlock);
    }

    function WithdrawRewardNativeToken() external onlyOwner {
        uint256 amountFee = (address(this).balance * percFeeAmount) / 100;
        payable(storagePersonal.getBurnContractAddress()).transfer(amountFee);
        uint256 amount = address(this).balance;
        payable(owner()).transfer(amount);
        RewardsNativeClaimed += amount;
    }

    function WithdrawTokensReward(address _token) external onlyOwner {
        require(
            _token != address(PersonalLockerToken),
            "You can't unlock the Tokens you locked with this function!"
        );

        uint256 amountFee = (IERC20(_token).balanceOf(address(this)) *
            percFeeAmount) / 100;
        IERC20(_token).transfer(
            storagePersonal.getBurnContractAddress(),
            amountFee
        );

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), amount);
        RewardsTokenClaimed[_token] += amount;
    }
}

contract DxLockLPDep is Ownable {
    decentralizedStorage PersonalLockerStorage;
    //mapping (address => bool) public maindapps;
    uint256 public lockerFees = 3 * 10**17;
    //    bool public feeCreationMode; //false = fees at creation
    uint256 public percFeeAmount = 1; //Divider is 1000 so 1 is 0.1%

    //uint256 public FeesEarned;
    address[] public LockerContractStorage;

    constructor(decentralizedStorage _lockerStorage) {
        PersonalLockerStorage = _lockerStorage;
    }

    function createLPLocker(
        address _lockingToken,
        uint256 _lockerEndTimeStamp,
        string memory _logo,
        uint256 _lockingAmount
    ) public payable returns (address newLock) {
        require(_lockingAmount > 0, "can't lock 0 Tokens");

        require(
            address(Ownable(Ownable(msg.sender).owner()).owner()) == owner(),
            "call from invalid address"
        );
        //require(maindapps[Ownable(msg.sender).owner()], "call from invalid address");
        /*if (_feeCreationMode) {
            require(msg.value >= lockerFees, "err : Please pay the price");
            payable(PersonalLockerStorage.getBurnContractAddress()).transfer(msg.value);
            FeesEarned += lockerFees;
        }
        */
        uint256 _counter = PersonalLockerStorage.getPersonalLockerCount(
            tx.origin
        );

        LaunchLPLocker createNewLock;
        createNewLock = new LaunchLPLocker(
            _lockingToken,
            _lockerEndTimeStamp,
            _counter,
            address(PersonalLockerStorage),
            _lockingAmount,
            percFeeAmount
        );

        require(
            IERC20(_lockingToken).transferFrom(
                msg.sender,
                address(createNewLock),
                _lockingAmount
            ),
            "Entry failed due to failed transfer."
        );

        PersonalLockerStorage.addNewLock(
            _lockingToken,
            _lockerEndTimeStamp,
            address(createNewLock),
            _lockingAmount,
            _logo
        );
        LockerContractStorage.push(address(createNewLock));

        return address(createNewLock);
    }

    function changeStorageContract(decentralizedStorage _lockerStorage)
        external
        onlyOwner
    {
        PersonalLockerStorage = _lockerStorage;
    }

    function changeFeePerc(uint256 _feeAmount) external onlyOwner {
        percFeeAmount = _feeAmount;
    }

    function updateFees(uint256 _newFees) public onlyOwner {
        require(_newFees >= 0, "invalid fees value");
        lockerFees = _newFees;
    }

    function getLockerCount() public view returns (uint256 isSize) {
        return LockerContractStorage.length;
    }

    function getAllLockers() public view returns (address[] memory) {
        address[] memory allTokens = new address[](
            LockerContractStorage.length
        );
        for (uint256 i = 0; i < LockerContractStorage.length; i++) {
            allTokens[i] = LockerContractStorage[i];
        }
        return allTokens;
    }

    function sendBNBstoBurnContract() public onlyOwner {
        address payable BurnContractAddress = payable(
            PersonalLockerStorage.getBurnContractAddress()
        );
        BurnContractAddress.transfer(address(this).balance);
    }

    /*
    function changeVault(address _vault) public onlyOwner {
        BurnContractAddress = payable(_vault);
    }
*/

    function withdrawStuckCurrency(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }
}