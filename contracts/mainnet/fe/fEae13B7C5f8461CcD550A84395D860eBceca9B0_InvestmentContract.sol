/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/investmetComponents/investmentLib.sol

pragma solidity ^0.8.0;

contract InvestmentLib {
    

    function convertToDecimal6(
        address _TokenAddress,
        uint256 _amountInStableCoin
    ) public view returns (uint256) {
        uint8 stableCoinDecimal = decimal(_TokenAddress);
        return _amountInStableCoin / 10 ** (stableCoinDecimal - 6);
    }

    function convertDecimal6ToAnyDecimal(
        address _TokenAddress,
        uint256 _amount
    ) public view returns (uint256) {
        uint8 tokenDecimal = decimal(_TokenAddress);
        return _amount * 10 ** (tokenDecimal - 6);
    }

    function decimal(address _TokenAddress) public view returns (uint8) {
        return IERC20Metadata(_TokenAddress).decimals();
    }

    function calculateAllocationTokenDecimal6ToDecimal6(
        uint256 amount,
        uint256 tokenPrice
    ) internal pure returns (uint256) {
        uint256 allocationToken = (100 * amount) / tokenPrice;
        return allocationToken;
    }

    function calculateAllocationTokenAnyDecimalTo6(
        address _tokenAddress,
        uint256 _investmentAmount,
        uint256 _tokenPrice
    ) internal view returns (uint256) {
        uint8 stableCoinDecimal = decimal(_tokenAddress);
        uint8 WSDMDecimal = 6;

        uint256 allocationToken = (100 * _investmentAmount) /
            _tokenPrice /
            10 ** (stableCoinDecimal - WSDMDecimal);
        return allocationToken;
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }
}


// File contracts/investmetComponents/payableTokens.sol


pragma solidity ^0.8.17;

contract PayableTokens {
    mapping(address => bool) private acceptedTokenMapping;


    function _isTokenAccepted(address _token) internal view returns (bool) {
        return acceptedTokenMapping[_token];
    }

    function _initializeTokenMappingFromList(address[] memory _acceptedToken) internal{
        for (uint256 i = 0; i < _acceptedToken.length; i++) {
            acceptedTokenMapping[_acceptedToken[i]] = true;
        }
    }

    function _addOrRemoveAcceptedToken(address _token, bool _status) internal{
        acceptedTokenMapping[_token] = _status;
    }
}


// File contracts/referral.sol

pragma solidity ^0.8.17;
contract ReferralContract is Ownable, InvestmentLib {
    address public invesmentContractAddress;
    address public immutable TWSDMTokenAddress;
    address public immutable USDTokenAddress;
    address public immutable TWSDMTreasury;
    address public immutable USDTreasury;
    ReferralStatistic referralStatistic;
    GeneralStatistic generalStatistic;

    enum StatusType {
        DONE,
        PENDING,
        CONFIRMED,
        REJECTED,
        CANCELED
    }
    enum Currency {
        TWSDM,
        USD
    }
    struct GeneralStatistic {
        uint256 totalAmountOfReferralInTWSDM;
        uint256 totalAmountOfReferralInUSD;
        uint256 totalAmountOfWithdrawnTWSDM;
        uint256 totalAmountOfWithdrawnUSD;
        uint256 totalAmountOfReferreeInTWSDM;
    }
    struct ReferralStatistic {
        uint256 totalNumberOfReferrer;
        uint256 totalNumberOfReferree;
    }
    struct Person {
        Referral referralBalance;
        Withdraw lastWithdraw;
        uint256 registredAt;
        string referrerClass;
    }

    struct Referral {
        uint256 bonusInUSD;
        uint256 bonusInTWSDM;
        uint256 blockInUSD;
        uint256 blockInTWSDM;
    }
    struct Withdraw {
        uint256 amountInTWSDM;
        uint256 amountInUSD;
        uint TWSDMWithdrawalPercentage;
        StatusType status;
    }
    struct ReferrerClass {
        uint256 shareOfReferrerToTWSDM;
        uint256 shareOfReferrerToUSD;
        uint256 shareOfRefereeToTWSDM;
        bool canRefer;
    }
    modifier onlyInvestmentContract() {
        require(
            msg.sender == invesmentContractAddress,
            "ReferralContract: only invesment contract"
        );
        _;
    }

    mapping(address => Person) public addressPersonMap;
    mapping(string => ReferrerClass) private referrerClassKeyReferrerClassMap;

    event newReferralClassAdded(string key);

    event newPersonAdded(address person, address referrer);
    event newReferral(
        address indexed referrer,
        address indexed referree,
        uint256 referrerBonusInTWSDM,
        uint256 referrerBonusInUSD
    );
    event Withdrawal(
        address indexed person,
        uint256 amountInTWSDM,
        uint256 amountInUSD,
        uint TWSDMWithdrawalPercentage,
        StatusType status
    );

    constructor(
        address _TWSDMTokenAddress,
        address _USDTokenAddress,
        address _TWSDMTreasury,
        address _USDTreasury,
        ReferrerClass memory _defaultReferrerClass
    ) {
        _addOrUpdateReferrerClass("default", _defaultReferrerClass);
        TWSDMTokenAddress = _TWSDMTokenAddress;
        USDTokenAddress = _USDTokenAddress;
        TWSDMTreasury = _TWSDMTreasury;
        USDTreasury = _USDTreasury;
    }

    function referral(
        address _referrer,
        address _referee,
        uint256 _investedAmount,
        uint256 _TWSDMPriceInCent
    ) public onlyInvestmentContract {
        if (_referrer != address(0)) {
            require(
                _referee != _referrer,
                "ReferralContract: You cannot refer yourself"
            );
            _setReferralData(
                _referrer,
                _referee,
                _investedAmount,
                _TWSDMPriceInCent
            );
            _setRefereeData(
                _referrer,
                _referee,
                _investedAmount,
                _TWSDMPriceInCent
            );
        }
        if (addressPersonMap[_referee].registredAt == 0)
            _addPerson(_referee, _referrer, "default");
    }

    function setInvestmentContractAddress(
        address _invesmentContractAddress
    ) public onlyOwner {
        invesmentContractAddress = _invesmentContractAddress;
    }

    function addPerson(
        address _person,
        string memory _referrerClassKey
    ) public onlyOwner {
        _addPerson(_person, msg.sender, _referrerClassKey);
    }

    function addOrUpdateReferrerClass(
        string memory _referrerClassKey,
        ReferrerClass memory _referrerClass
    ) public onlyOwner {
        _addOrUpdateReferrerClass(_referrerClassKey, _referrerClass);
    }

    function updatePersonReferrerClass(
        address _person,
        string memory _referrerClassKey
    ) public onlyOwner {
        addressPersonMap[_person].referrerClass = _referrerClassKey;
    }

    function requestWithdraw(uint _TWSDMWithdrawalPercentage) public {
        require(
            _TWSDMWithdrawalPercentage <= 100,
            "ReferralContract: The input value must be between 0 and 100"
        );
        Withdraw memory _lastWithdraw = addressPersonMap[msg.sender]
            .lastWithdraw;

        require(
            _lastWithdraw.status != StatusType.PENDING,
            "ReferralContract: You have already registered a withdrawal request"
        );

        require(
            addressPersonMap[msg.sender].referralBalance.bonusInUSD >0 ||
            addressPersonMap[msg.sender].referralBalance.bonusInTWSDM >0 ,
            "ReferralContract: Insufficient referral balance"
        );

        uint256 _amountInTWSDM = (addressPersonMap[msg.sender]
            .referralBalance
            .bonusInTWSDM * _TWSDMWithdrawalPercentage) / 100;
        uint256 _amountInUSD = (addressPersonMap[msg.sender]
            .referralBalance
            .bonusInUSD * (100 - _TWSDMWithdrawalPercentage)) / 100;

        Withdraw memory _withdraw = Withdraw({
            amountInTWSDM: _amountInTWSDM,
            amountInUSD: _amountInUSD,
            status: StatusType.PENDING,
            TWSDMWithdrawalPercentage: _TWSDMWithdrawalPercentage
        });
        addressPersonMap[msg.sender].lastWithdraw = _withdraw;
        addressPersonMap[msg.sender].referralBalance.blockInTWSDM = addressPersonMap[msg.sender].referralBalance.bonusInTWSDM;
        addressPersonMap[msg.sender].referralBalance.blockInUSD= addressPersonMap[msg.sender].referralBalance.bonusInUSD;

        addressPersonMap[msg.sender].referralBalance.bonusInTWSDM = 0;
        addressPersonMap[msg.sender].referralBalance.bonusInUSD = 0;

        emit Withdrawal(
            msg.sender,
            _amountInTWSDM,
            _amountInUSD,
            _TWSDMWithdrawalPercentage,
            StatusType.PENDING
        );
    }

    function cancelRequestWithdraw() public {
        Withdraw storage _lastWithdraw = addressPersonMap[msg.sender]
            .lastWithdraw;
        require(
            _lastWithdraw.status == StatusType.PENDING,
            "ReferralContract: No requests have been registered for you"
        );
        _lastWithdraw.status = StatusType.CANCELED;
        _increaseBalanceAmount(
            msg.sender        );
        emit Withdrawal(
            msg.sender,
            _lastWithdraw.amountInTWSDM,
            _lastWithdraw.amountInUSD,
            _lastWithdraw.TWSDMWithdrawalPercentage,
            _lastWithdraw.status
        );
    }

    function withdraw(address _person, StatusType _status) public onlyOwner {
        Withdraw storage _lastWithdraw = addressPersonMap[_person].lastWithdraw;

        require(
            _lastWithdraw.status == StatusType.PENDING,
            "ReferralContract: No withdrawal request has been registered for this person"
        );

        if (_status == StatusType.REJECTED) {
            _lastWithdraw.status = _status;
            _increaseBalanceAmount(
                _person
            );
        } else if (_status == StatusType.CONFIRMED) {
            _lastWithdraw.status = _status;

            if (_lastWithdraw.amountInUSD > 0) {
                safeTransferFrom(
                    USDTokenAddress,
                    USDTreasury,
                    _person,
                    convertDecimal6ToAnyDecimal(
                        USDTokenAddress,
                        _lastWithdraw.amountInUSD
                    )
                );
                generalStatistic.totalAmountOfWithdrawnUSD += _lastWithdraw
                    .amountInUSD;
            }
            if (_lastWithdraw.amountInTWSDM > 0) {
                safeTransferFrom(
                    TWSDMTokenAddress,
                    TWSDMTreasury,
                    _person,
                    _lastWithdraw.amountInTWSDM
                );
                generalStatistic.totalAmountOfWithdrawnTWSDM += _lastWithdraw
                    .amountInTWSDM;
            }
            addressPersonMap[_person].referralBalance.blockInTWSDM = 0;   
            addressPersonMap[_person].referralBalance.blockInUSD = 0;

        } else {
            revert("ReferralContract: Unexpected status!");
        }
        emit Withdrawal(
            _person,
            _lastWithdraw.amountInTWSDM,
            _lastWithdraw.amountInUSD,
            _lastWithdraw.TWSDMWithdrawalPercentage,
            _lastWithdraw.status
        );
    }

    // getter

    function getPersonData(
        address _person
    ) public view returns (Person memory) {
        return addressPersonMap[_person];
    }

    function getPersonAvailableBalance(
        address _person
    ) public view returns (uint256 TWSDM, uint256 USD) {
        TWSDM = addressPersonMap[_person].referralBalance.bonusInTWSDM;
        USD = addressPersonMap[_person].referralBalance.bonusInUSD;
    }

    function getNumberOfTotalRefereeAndReferrer()
        public
        view
        returns (ReferralStatistic memory)
    {
        return (referralStatistic);
    }

    function getGeneralStatisticsOfPaidTokens()
        public
        view
        returns (GeneralStatistic memory)
    {
        return (generalStatistic);
    }

    function getReferrerClassByKey(
        string memory _referrerClassKey
    ) public view returns (ReferrerClass memory) {
        return referrerClassKeyReferrerClassMap[_referrerClassKey];
    }

    // private function

    function _setReferralData(
        address _referrer,
        address _referee,
        uint256 _investedAmount,
        uint256 _TWSDMPriceInCent
    ) private {
        ReferrerClass
            memory refererClassData = referrerClassKeyReferrerClassMap[
                addressPersonMap[_referrer].referrerClass
            ];

        require(
            refererClassData.canRefer,
            "ReferralContract: Referrer not found with this address"
        );

        uint256 _referrerBonusInUSD = ((refererClassData.shareOfReferrerToUSD) *
            _investedAmount) / 100;
        uint256 _referrerBonusInTWSDM = ((
            refererClassData.shareOfReferrerToTWSDM
        ) * _investedAmount) / _TWSDMPriceInCent;

        addressPersonMap[_referrer]
            .referralBalance
            .bonusInUSD += _referrerBonusInUSD;
        addressPersonMap[_referrer]
            .referralBalance
            .bonusInTWSDM += _referrerBonusInTWSDM;
        generalStatistic.totalAmountOfReferralInTWSDM += _referrerBonusInTWSDM;
        generalStatistic.totalAmountOfReferralInUSD += _referrerBonusInUSD;
        emit newReferral(
            _referrer,
            _referee,
            _referrerBonusInTWSDM,
            _referrerBonusInUSD
        );
    }

    function _setRefereeData(
        address _referrer,
        address _referee,
        uint256 _investedAmount,
        uint256 _TWSDMPriceInCent
    ) private {
        ReferrerClass
            memory refererClassData = referrerClassKeyReferrerClassMap[
                addressPersonMap[_referrer].referrerClass
            ];

        uint256 _refereeBonusInTWSDM = ((refererClassData.shareOfRefereeToTWSDM) *
            _investedAmount) / _TWSDMPriceInCent;

        referralStatistic.totalNumberOfReferree += 1;
        generalStatistic.totalAmountOfReferreeInTWSDM += _refereeBonusInTWSDM;
        
        safeTransferFrom(
            TWSDMTokenAddress,
            TWSDMTreasury,
            _referee,
            _refereeBonusInTWSDM
        );
    }

    function _addPerson(
        address _person,
        address _referrer,
        string memory _referrerClassKey
    ) private {
        require(
            addressPersonMap[_person].registredAt == 0,
            "ReferralContract: This address is in our persons list"
        );
        addressPersonMap[_person].registredAt = block.timestamp;
        addressPersonMap[_person].referrerClass = _referrerClassKey;
        referralStatistic.totalNumberOfReferrer += 1;
        emit newPersonAdded(_person, _referrer);
    }

    function _addOrUpdateReferrerClass(
        string memory _referrerClassKey,
        ReferrerClass memory _ReferrerClass
    ) private {
        referrerClassKeyReferrerClassMap[_referrerClassKey] = _ReferrerClass;
        emit newReferralClassAdded(_referrerClassKey);
    }

    function _increaseBalanceAmount(
        address _person
    ) private {
        addressPersonMap[_person].referralBalance.bonusInTWSDM +=addressPersonMap[_person].referralBalance.blockInTWSDM;
        addressPersonMap[_person].referralBalance.blockInTWSDM = 0;   
        addressPersonMap[_person].referralBalance.bonusInUSD +=addressPersonMap[_person].referralBalance.blockInUSD;
        addressPersonMap[_person].referralBalance.blockInUSD = 0;
    }
}


// File contracts/investment.sol

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

contract InvestmentContract is Ownable, PayableTokens, InvestmentLib {
    using Counters for Counters.Counter;
    address public immutable TWSDMTokenAddress;
    address public immutable investmentWallet;
    address referralContractAddress;
    address immutable TWSDMTreasury;
    uint8 currentRoundNumber;
    Counters.Counter public countOfRoundNumber;

//TODO:per round
    struct Participant{
        uint256 totalInvestor;
        uint256 totalInvestment;
    }

    struct Investment {
        uint256 investorAmountDeposit;
        uint256 allocatedTWSDMToken;
        address tokenContractAddress;
        uint256 roundNumber;
    }
    struct InvestmentRound {
        uint256 startTime;
        uint256 TWSDMPriceInCent;
        uint256 minTicketSizeInUSD;
        uint256 maxTicketSizeInUSD;
        uint256 hardCapInUSD;
        uint256 totalInvestedInUSD;
        bool isFinished;
    }

    mapping(uint256 => InvestmentRound) private roundIdRoundMap;
    mapping(address => Investment[]) private addressInvestorMap;
    mapping(uint256 => Participant) private roundIdParticipantMap;

    modifier addressIsNotZero(address _address) {
        require(
            address(0) != _address,
            "InvestmentContract: Address is equal to ZERO"
        );
        _;
    }

    modifier investmentRoundIsNotStarted(uint256 _roundNumber) {
        require(
            roundIdRoundMap[_roundNumber].startTime > block.timestamp,
            "InvestmentContract: Investment Round is started"
        );
        _;
    }
    modifier investmentRoundIsExisted(uint256 _roundNumber) {
        require(
            _roundNumber > 0,
            "InvestmentContract: There is no zero round"
        );
        _;
    }

    event newInvestment(
        address indexed investor,
        uint256 indexed roundNumber,
        uint256 allocatedTWSDMToken,
        address tokenAddress,
        uint256 investmentAmount
    );

    //test
    constructor(
        address _TWSDMTokenAddress,
        address _TWSDMTreasury,
        address _investmentWallet,
        address _referralContractAddress,
        address[] memory _acceptedToken
    ) {
        TWSDMTokenAddress = _TWSDMTokenAddress;
        TWSDMTreasury = _TWSDMTreasury;
        investmentWallet = _investmentWallet;
        referralContractAddress = _referralContractAddress;
        _initializeTokenMappingFromList(_acceptedToken);
    }

    function addOrRemoveAcceptedToken(address token, bool status) public onlyOwner{
        _addOrRemoveAcceptedToken(token,status);
    }

    function setCurrentRoundNumber(uint8 _roundNumber) public onlyOwner {
        currentRoundNumber = _roundNumber;
    }

    function createNewRound(
        uint256 _startTime,
        uint256 _TWSDMPriceInCent,
        uint256 _minTicketSizeInUSD,
        uint256 _maxTicketSizeInUSD,
        uint256 _hardCapInUSD
    ) public onlyOwner {
        countOfRoundNumber.increment();

        InvestmentRound memory newInvestmentRound = InvestmentRound({
            startTime: _startTime,
            TWSDMPriceInCent: _TWSDMPriceInCent,
            minTicketSizeInUSD: _minTicketSizeInUSD,
            maxTicketSizeInUSD: _maxTicketSizeInUSD,
            hardCapInUSD: _hardCapInUSD,
            totalInvestedInUSD: 0,
            isFinished: false
        });
        roundIdRoundMap[countOfRoundNumber.current()] = newInvestmentRound;
    }

    function changeRoundStartTime(
        uint256 _roundNumber,
        uint256 _newStartTime
    ) public onlyOwner investmentRoundIsExisted(_roundNumber) investmentRoundIsNotStarted(_roundNumber) {
        roundIdRoundMap[_roundNumber].startTime = _newStartTime;
    }

    function changeHardCapInUSD(
        uint256 _roundNumber,
        uint256 _hardCapInUSD
    ) public onlyOwner investmentRoundIsExisted(_roundNumber) investmentRoundIsNotStarted(_roundNumber) {
        roundIdRoundMap[_roundNumber].hardCapInUSD = _hardCapInUSD;
    }

    function changeMinTicketSizeInUSD(
        uint256 _roundNumber,
        uint256 _minTicketSizeInUSD
    ) public onlyOwner investmentRoundIsExisted(_roundNumber) {
        roundIdRoundMap[_roundNumber].minTicketSizeInUSD = _minTicketSizeInUSD;
    }

    function changeMaxTicketSizeInUSD(
        uint256 _roundNumber,
        uint256 _maxTicketSizeInUSD
    ) public onlyOwner investmentRoundIsExisted(_roundNumber) {
        roundIdRoundMap[_roundNumber].maxTicketSizeInUSD = _maxTicketSizeInUSD;
    }

    function changeTWSDMPriceInCent(
        uint256 _roundNumber,
        uint256 _TWSDMPriceInCent
    ) public onlyOwner investmentRoundIsExisted(_roundNumber) investmentRoundIsNotStarted(_roundNumber) {
        roundIdRoundMap[_roundNumber].TWSDMPriceInCent = _TWSDMPriceInCent;
    }

    function changeRoundFinishedStatus(
        uint256 _roundNumber,
        bool _isFinished
    ) public onlyOwner investmentRoundIsExisted(_roundNumber) {
        roundIdRoundMap[_roundNumber].isFinished = _isFinished;
    }

    function investByInvestor(
        address _tokenContractAddress,
        uint256 _investmentAmount,
        address _referralAddress
    ) public addressIsNotZero(_tokenContractAddress) investmentRoundIsExisted(currentRoundNumber) {
        require(
            _isTokenAccepted(_tokenContractAddress),
            "InvestmentContract: this token is not whitelisted!"
        );
        require(
            block.timestamp >= roundIdRoundMap[currentRoundNumber].startTime &&
            !roundIdRoundMap[currentRoundNumber].isFinished,
            "InvestmentContract: this round is not started or finished already"
        );
        uint256 _investmentAmountDecimal6 = convertToDecimal6(
            _tokenContractAddress,
            _investmentAmount
        );
        require(
            _investmentAmountDecimal6 >=
                roundIdRoundMap[currentRoundNumber].minTicketSizeInUSD &&
                _investmentAmountDecimal6 <=
                roundIdRoundMap[currentRoundNumber].maxTicketSizeInUSD,
            "InvestmentContract: The investment amount is out of range!"
        );
        require(
            roundIdRoundMap[currentRoundNumber].totalInvestedInUSD + _investmentAmountDecimal6 <=
                roundIdRoundMap[currentRoundNumber].hardCapInUSD,
            "InvestmentContract: The final investment amount is reached"
        );

        safeTransferFrom(
            _tokenContractAddress,
            msg.sender,
            investmentWallet,
            _investmentAmount
        );

        uint256 allocatedToken = calculateAllocationTokenDecimal6ToDecimal6(
            _investmentAmountDecimal6,
            roundIdRoundMap[currentRoundNumber].TWSDMPriceInCent
        );
        safeTransferFrom(
            TWSDMTokenAddress,
            TWSDMTreasury,
            msg.sender,
            allocatedToken
        );

        Investment memory _newInvestment = Investment({
            investorAmountDeposit: _investmentAmount,
            roundNumber: currentRoundNumber,
            allocatedTWSDMToken: allocatedToken,
            tokenContractAddress: _tokenContractAddress
        });
        _increaseParticipationStatistics();
        addressInvestorMap[msg.sender].push(_newInvestment);
        _increaseTotalInvestedInUSDInCurrentRound(_investmentAmountDecimal6);
        ReferralContract(referralContractAddress).referral(
            _referralAddress,
            msg.sender,
            _investmentAmountDecimal6,
            roundIdRoundMap[currentRoundNumber].TWSDMPriceInCent
        );
        
        emit newInvestment(
            msg.sender,
            currentRoundNumber,
            allocatedToken,
            _tokenContractAddress,
            _investmentAmountDecimal6
        );
    }


    function _increaseTotalInvestedInUSDInCurrentRound(
        uint256 _amount
    ) private {
        roundIdRoundMap[currentRoundNumber].totalInvestedInUSD += _amount;
    }

    function _increaseParticipationStatistics() private {
        if (addressInvestorMap[msg.sender].length == 0) roundIdParticipantMap[currentRoundNumber].totalInvestor += 1;
        roundIdParticipantMap[currentRoundNumber].totalInvestment += 1;
        
    }

    function setReferralContractAddress(
        address _referralContractAddress
    ) public onlyOwner {
        referralContractAddress = _referralContractAddress;
    }

    function getParticipationRate(uint256 _roundNumber)
        public
        view
        returns (Participant memory)
    {
        return roundIdParticipantMap[_roundNumber];
    }

    function calculateAllocationToken(
        address _tokenAddress,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 _tokenPrice = roundIdRoundMap[currentRoundNumber]
            .TWSDMPriceInCent;
        return
            calculateAllocationTokenAnyDecimalTo6(
                _tokenAddress,
                _amount,
                _tokenPrice
            );
    }

    function getInvestorInvestments(
        address _investorAddress
    ) public view returns (Investment[] memory) {
        return
            addressInvestorMap[_investorAddress];
    }

    function getCurrentRoundNumber() public view returns (uint256) {
        return currentRoundNumber;
    }

    function getRoundDetails(
        uint256 _roundNumber
    ) public view returns (InvestmentRound memory) {
        return roundIdRoundMap[_roundNumber];
    }

}