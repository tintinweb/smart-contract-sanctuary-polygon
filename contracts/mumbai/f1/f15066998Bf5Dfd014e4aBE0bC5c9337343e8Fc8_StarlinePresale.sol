// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address owner) external view returns (uint256);

    function totalSupply(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(address from, address to, uint256 value) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

abstract contract Ownable {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

contract StarlinePresale is Ownable {

    receive() external payable {
    }
    
    struct Payments {
        uint256 partipatedAmount;
        uint256 tokenAmount;
        IERC20 participationToken;
        bool claimedBack;
    }

    struct User {
        uint256 claimableTokenAmount;
        Payments[] payments;
        uint256 buyCount;
        bool exist;
        bool claimed;
    }

    IERC20 public presaleToken;
    IERC20 public WBTC;
    IERC20 public USDT;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public minAmount;
    uint256 public presaleStartTime;
    uint256 public presaleEndTime;
    uint256 public tokenPrice;
    uint256 public soldTokens;

    uint256 public capCounter;

    AggregatorV3Interface public btcPriceFeed;
    AggregatorV3Interface public ethPriceFeed;
    AggregatorV3Interface public usdtPriceFeed;

    mapping(address => User) public users;
    
    constructor() {
        presaleToken = IERC20(0x4db66A485f19Cd50007353b1647f4231A2c84fca);
        WBTC = IERC20(0x056cda0447DE62b09F239887AAb9C9d11C3bCf6d);
        USDT = IERC20(0xbedD80C5e23ef39078f3d1fdcF12025FEd87fDF9);
        minAmount = 10 * (10 ** presaleToken.decimals());
        softCap = 5000 ether;
        hardCap = 50000 ether;
        tokenPrice = 0.0003 ether;
        ethPriceFeed = AggregatorV3Interface(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
        );
        btcPriceFeed = AggregatorV3Interface(
            0x007A22900a3B98143368Bd5906f8E17e9867581b
        );
        usdtPriceFeed = AggregatorV3Interface(
            0x572dDec9087154dC5dfBB1546Bb62713147e0Ab0
        );

        presaleStartTime = 1688324400;
        presaleEndTime = 1693767600;
    }

    function buyWithEth() external payable {
        require(
            presaleStartTime < block.timestamp,
            "Presale is not started Yet"
        );
        require(
            capCounter < hardCap,
            "Hardcap is Reached. You cannot buy futher token"
        );
        uint256 tokenAmount;
        unchecked {
            tokenAmount = (msg.value * 1e18) / tokenPrice;
        }
        require(
            tokenAmount >= minAmount,
            "You cannot buy that much small amount of Token. Check the minimum token Amount"
        );

        users[msg.sender]
            .payments[users[msg.sender].buyCount]
            .partipatedAmount += msg.value;
        users[msg.sender]
            .payments[users[msg.sender].buyCount]
            .tokenAmount += tokenAmount;
        users[msg.sender].claimableTokenAmount += tokenAmount;
        users[msg.sender].exist = true;
        users[msg.sender].buyCount++;

        capCounter += msg.value;
        soldTokens += tokenAmount;
    }

    function buyWithUSDT(uint256 _amount) external {
        require(
            presaleStartTime < block.timestamp,
            "Presale is not started Yet"
        );
        require(
            capCounter < hardCap,
            "Hardcap is Reached. You cannot buy futher token"
        );
        uint256 tokenAmount = getTokenOutAmount(USDT, _amount);
        require(
            tokenAmount >= minAmount,
            "You cannot buy that much small amount of Token. Check the minimum token Amount"
        );

        users[msg.sender]
            .payments[users[msg.sender].buyCount]
            .partipatedAmount += _amount;
        users[msg.sender]
            .payments[users[msg.sender].buyCount]
            .tokenAmount += tokenAmount;
        users[msg.sender]
            .payments[users[msg.sender].buyCount]
            .participationToken = USDT;
        users[msg.sender].claimableTokenAmount += tokenAmount;
        (!users[msg.sender].exist) ? (users[msg.sender].exist = true) : true;
        users[msg.sender].buyCount++;

        capCounter += (_amount * getLatestPriceUSDT()) / getLatestPriceETH();
        soldTokens += tokenAmount;
    }

    function buyWithWBTC(uint256 _amount) external {
        require(
            presaleStartTime < block.timestamp,
            "Presale is not started Yet"
        );
        require(
            capCounter < hardCap,
            "Hardcap is Reached. You cannot buy futher token"
        );
        uint256 tokenAmount = getTokenOutAmount(WBTC, _amount);

        require(
            tokenAmount >= minAmount,
            "You cannot buy that much small amount of Token. Check the minimum token Amount"
        );

        WBTC.transferFrom(msg.sender, address(this), _amount);

        users[msg.sender]
            .payments[users[msg.sender].buyCount]
            .partipatedAmount += _amount;
        users[msg.sender]
            .payments[users[msg.sender].buyCount]
            .tokenAmount += tokenAmount;
        users[msg.sender]
            .payments[users[msg.sender].buyCount]
            .participationToken = WBTC;
        users[msg.sender].claimableTokenAmount += tokenAmount;
        (!users[msg.sender].exist) ? (users[msg.sender].exist = true) : true;
        users[msg.sender].buyCount++;
        capCounter +=
            (_amount * 1e10 * getLatestPriceBTC()) /
            getLatestPriceETH();
        soldTokens += tokenAmount;
    }

    function claimPresaleToken() external {
        require(presaleEndTime < block.timestamp, "Presale is not ended Yet");
        require(
            capCounter > softCap,
            "Softcap is not Reached. You cannot claim your funds back"
        );
        require(
            users[msg.sender].exist,
            "You claimed your token or you are not part of presale"
        );
        presaleToken.transfer(
            msg.sender,
            users[msg.sender].claimableTokenAmount
        );
        users[msg.sender].exist = false;
    }
    
    function claimFundsBack(uint256 index) external {
        require(
            users[msg.sender].exist,
            "You claimed token , So that you have not pending amount in this sale anymore"
        );
        require(
            !users[msg.sender].payments[index].claimedBack,
            "You already claimed back your token at this index"
        );
        require(
            capCounter < softCap,
            "You cannot claim funds, Instead of this please claim presale token"
        );
        require(block.timestamp > presaleEndTime, "Presale is not ended yet");

        if (
            address(users[msg.sender].payments[index].participationToken) ==
            address(0)
        ) {
            payable(msg.sender).transfer(
                users[msg.sender].payments[index].partipatedAmount
            );
            users[msg.sender].payments[index].claimedBack = true;
            users[msg.sender].claimableTokenAmount -= users[msg.sender]
                .payments[index]
                .tokenAmount;
        } else {
            users[msg.sender].payments[index].participationToken.transfer(
                msg.sender,
                users[msg.sender].payments[index].partipatedAmount
            );
            users[msg.sender].payments[index].claimedBack = true;
            users[msg.sender].claimableTokenAmount -= users[msg.sender]
                .payments[index]
                .tokenAmount;
        }
    }

    // ++++++++++++++++| Getter Functions |++++++++++++++++
    function getTokenOutAmount(
        IERC20 _exhangeToken,
        uint256 amount
    ) public view returns (uint256 _amount) {
        if (_exhangeToken == USDT) {
            unchecked {
                return (
                    ((amount * getLatestPriceUSDT() * 1e18) /
                        (tokenPrice * getLatestPriceETH()))
                );
            }
        } else if (_exhangeToken == WBTC) {
            unchecked {
                return (
                    (((_amount * getLatestPriceBTC()) * 1e28) /
                        (tokenPrice * getLatestPriceETH()))
                );
            }
        } else if (address(_exhangeToken) == address(0)) {
            return (amount * 1e18) / tokenPrice;
        } else {
            return 0;
        }
    }

    function getUserDataByIndex(
        address _user,
        uint _index
    )
        public
        view
        returns (
            uint256 partipatedAmount,
            uint256 tokenAmount,
            IERC20 participationToken,
            bool claimedBack
        )
    {
        partipatedAmount = users[_user].payments[_index].partipatedAmount;
        tokenAmount = users[_user].payments[_index].tokenAmount;
        participationToken = users[_user].payments[_index].participationToken;
        claimedBack = users[_user].payments[_index].claimedBack;
    }

    function getLatestPriceETH() public view returns (uint256) {
        (, int256 price, , , ) = ethPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getLatestPriceBTC() public view returns (uint256) {
        (, int256 price, , , ) = btcPriceFeed.latestRoundData();
        return uint256(price);
    }

    function getLatestPriceUSDT() public view returns (uint256) {
        (, int256 price, , , ) = usdtPriceFeed.latestRoundData();
        return uint256(price);
    }

    // ++++++++++++++++| Setter Functions ( OnlyOwner )|++++++++++++++++

    function changeWBTC(IERC20 _token) external onlyOwner {
        WBTC = _token;
    }
    
    function changeUSDT(IERC20 _token) external onlyOwner {
        USDT = _token;
    }
    function changePresale(IERC20 _token) external onlyOwner {
        presaleToken = _token;
    }
    
    function changeSoftCap(uint256 _softCap) external onlyOwner {
        softCap = _softCap;
    }

    function changeHardCap(uint256 _hardCap) external onlyOwner {
        hardCap = _hardCap;
    }

    function changeMinTokenAmount(uint256 _minAmount) external onlyOwner {
        minAmount = _minAmount;
    }

    function changeEndTime(uint256 _presaleEndTime) external onlyOwner {
        presaleEndTime = _presaleEndTime;
    }

    function changeStartTime(uint256 _presaleStartTime) external onlyOwner {
        presaleStartTime = _presaleStartTime;
    }

    function changeTokenPrice(uint256 _presaleTokenPrice) external onlyOwner {
        tokenPrice = _presaleTokenPrice;
    }

    function changeETHAggregator(
        AggregatorV3Interface _aggregator
    ) external onlyOwner {
        ethPriceFeed = _aggregator;
    }

    function changeBTCAggregator(
        AggregatorV3Interface _aggregator
    ) external onlyOwner {
        btcPriceFeed = _aggregator;
    }

    function changeUSDTAggregator(
        AggregatorV3Interface _aggregator
    ) external onlyOwner {
        usdtPriceFeed = _aggregator;
    }

    function withdrawTokens(IERC20 _token, uint256 amount) external onlyOwner {
        _token.transfer(msg.sender, amount);
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }
}