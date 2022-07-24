/**
 *Submitted for verification at polygonscan.com on 2022-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

// import "hardhat/console.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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

interface ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

interface TMEEBIT {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract randoms {
    uint256 private nonce1 = 0;
    uint256 private nonce2 = 0;
    uint256 private nonce3 = 0;
    uint256 private nonce4 = 0;

    function random1() public returns (uint256) {
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce1,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % 2;
        nonce1++;
        return index;
    }

    function random2() public returns (uint256) {
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce2,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % 2;
        nonce2++;
        return index;
    }

    function random3() public returns (uint256) {
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce3,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % 2;
        nonce3++;
        return index;
    }

    function random4() public returns (uint256) {
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce4,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % 2;
        nonce4++;
        return index;
    }
}

contract DoubleOrNothing is ERC721TokenReceiver, Ownable, randoms {
    TMEEBIT private tmeebits;

    using SafeMath for uint256;

    uint256 internal nonce = 0;

    uint256 public DexFeePercent = 4;

    uint256 public balance25;
    uint256 public balance50;
    uint256 public balance100;
    uint256 public balance200;

    TMEEBIT internal defultContract;

    uint256 public totaltried = 0;
    uint256 public totalToken = 0;

    uint256 adminFeeAmount;

    uint256 public id = 0;

    bool private reentrancyLock = false;

    bool public isMarketEnabled = false;

    struct PlayerDeposit {
        uint256 amount;
        uint256 totalWithdraw;
        uint256 wasSuccess;
        uint256 time;
    }

    struct UserToken {
        uint256[] tokenIds;
        address ownerToken;
        uint256 commission;
        bool active;
        uint256 totalToken;
    }

    struct UserWalletAddressAndTokenCount {
        address public_key;
    }

    struct History {
        uint256 tokenId;
        uint256 wasSuccess;
        address owner;
        uint256 price;
        PlayerDeposit[] deposits;
    }

    struct totalTransaction {
        uint256 userAmount;
        address userAdress;
        uint256 userTxSuccess;
    }

    struct Offer {
        bool isForSale;
        uint256 punkIndex;
        address seller;
        address onlySellTo;
    }

    mapping(uint256 => totalTransaction) public listTX;

    mapping(address => History) public txHistorys;

    mapping(uint256 => Offer) public punksOfferedForSale;

    mapping(address => address) public contractAddress;

    mapping(address => UserToken) public userTokens;

    mapping(uint256 => UserWalletAddressAndTokenCount) public userAddress;

    mapping(address => bool) public blockList;

    constructor(address _defultContract) {
        defultContract = TMEEBIT(address(_defultContract));
    }

    // function deposit() external payable {}

    function contributionsInfo(address _addr)
        external
        view
        returns (
            uint256[] memory amounts,
            uint256[] memory totalWithdraws,
            uint256[] memory issuccess
        )
    {
        History storage txHistory = txHistorys[_addr];

        // uint256[] memory _endTimes = new uint256[](txHistory.deposits.length);
        uint256[] memory _amounts = new uint256[](txHistory.deposits.length);
        uint256[] memory _totalWithdraws = new uint256[](
            txHistory.deposits.length
        );
        uint256[] memory _wasSuccess = new uint256[](txHistory.deposits.length);
        // Create arrays with deposits info, each index is related to a deposit
        for (uint256 i = 0; i < txHistory.deposits.length; i++) {
            PlayerDeposit storage dep = txHistory.deposits[i];
            _amounts[i] = dep.amount;
            _totalWithdraws[i] = dep.totalWithdraw;
            _wasSuccess[i] = dep.wasSuccess;
        }

        return (_amounts, _totalWithdraws, _wasSuccess);
    }

    function transactionInfo()
        external
        view
        returns (
            uint256[] memory amounts,
            address[] memory useradress,
            uint256[] memory issuccess
        )
    {
        uint256[] memory _amounts = new uint256[](totaltried);
        address[] memory _useradress = new address[](totaltried);
        uint256[] memory _wasSuccess = new uint256[](totaltried);

        for (uint256 i = 0; i < totaltried; i++) {
            totalTransaction storage transact = listTX[i];

            _amounts[i] = transact.userAmount;
            _useradress[i] = transact.userAdress;
            _wasSuccess[i] = transact.userTxSuccess;
        }

        return (_amounts, _useradress, _wasSuccess);
    }

    function tryChance() public payable {
        // require(
        //     msg.value >= minPric,
        //     "The price entered by you is lower than the average contract price..."
        // );
        uint256 rand;

        require(
            msg.value == 250000000||
            msg.value == 2500000000000000||
            msg.value == 25e18 ||
                msg.value == 50e18 ||
                msg.value == 100e18 ||
                msg.value == 200e18,
                "value "
        );
        if (msg.value == 2500000000000000) {
            rand = random1();
            uint256 fee = (msg.value * 350) / 1000;
            uint256 adminPrice = (fee * 150) / 1000;

            adminFeeAmount += adminPrice;

            if (totalToken > 0) {
                uint256 usersFee = (fee * 20) / 1000;

                uint256 userFee = usersFee / totalToken;

                for (uint256 i = 0; i < totalToken; i++) {
                    address userAddr = userAddress[i].public_key;

                    if (userAddr != address(0)) {
                        UserToken storage _user = userTokens[userAddr];

                        uint256 countUserToken = _user.totalToken;

                        uint256 userCommission = userFee * countUserToken;

                        _user.commission += userCommission;
                    }
                }
            }

            balance25 += msg.value;
        }

        if (msg.value == 250000000) {
            rand = random1();
            uint256 fee = (msg.value * 350) / 1000;
            uint256 adminPrice = (fee * 150) / 1000;

            adminFeeAmount += adminPrice;

            if (totalToken > 0) {
                uint256 usersFee = (fee * 20) / 1000;

                uint256 userFee = usersFee / totalToken;

                for (uint256 i = 0; i < totalToken; i++) {
                    address userAddr = userAddress[i].public_key;

                    if (userAddr != address(0)) {
                        UserToken storage _user = userTokens[userAddr];

                        uint256 countUserToken = _user.totalToken;

                        uint256 userCommission = userFee * countUserToken;

                        _user.commission += userCommission;
                    }
                }
            }

            balance25 += msg.value;
        }

        if (msg.value == 25e18) {
            rand = random1();

            uint256 fee = (msg.value * 350) / 1000;
            uint256 adminPrice = (fee * 150) / 1000;

            adminFeeAmount += adminPrice;

            if (totalToken > 0) {
                uint256 usersFee = (fee * 20) / 1000;

                uint256 userFee = usersFee / totalToken;

                for (uint256 i = 0; i < totalToken; i++) {
                    address userAddr = userAddress[i].public_key;

                    if (userAddr != address(0)) {
                        UserToken storage _user = userTokens[userAddr];

                        uint256 countUserToken = _user.totalToken;

                        uint256 userCommission = userFee * countUserToken;

                        _user.commission += userCommission;
                    }
                }
            }

            balance25 += msg.value;
        }

        if (msg.value == 50e18) {
            rand = random2();

            uint256 fee = (msg.value * 350) / 1000;
            uint256 adminPrice = (fee * 150) / 1000;

            adminFeeAmount += adminPrice;

            if (totalToken > 0) {
                uint256 usersFee = (fee * 20) / 1000;

                uint256 userFee = usersFee / totalToken;

                for (uint256 i = 0; i < totalToken; i++) {
                    address userAddr = userAddress[i].public_key;

                    if (userAddr != address(0)) {
                        UserToken storage _user = userTokens[userAddr];

                        uint256 countUserToken = _user.totalToken;

                        uint256 userCommission = userFee * countUserToken;

                        _user.commission += userCommission;
                    }
                }
            }

            balance50 += msg.value;
        }

        if (msg.value == 100e18) {
            rand = random2();

            uint256 fee = (msg.value * 350) / 1000;
            uint256 adminPrice = (fee * 150) / 1000;

            adminFeeAmount += adminPrice;

            if (totalToken > 0) {
                uint256 usersFee = (fee * 20) / 1000;

                uint256 userFee = usersFee / totalToken;

                for (uint256 i = 0; i < totalToken; i++) {
                    address userAddr = userAddress[i].public_key;

                    if (userAddr != address(0)) {
                        UserToken storage _user = userTokens[userAddr];

                        uint256 countUserToken = _user.totalToken;

                        uint256 userCommission = userFee * countUserToken;

                        _user.commission += userCommission;
                    }
                }
            }

            balance100 += msg.value;
        }

        if (msg.value == 200e18) {
            rand = random2();

            uint256 fee = (msg.value * 350) / 1000;
            uint256 adminPrice = (fee * 150) / 1000;

            adminFeeAmount += adminPrice;

            if (totalToken > 0) {
                uint256 usersFee = (fee * 20) / 1000;

                uint256 userFee = usersFee / totalToken;

                for (uint256 i = 0; i < totalToken; i++) {
                    address userAddr = userAddress[i].public_key;

                    if (userAddr != address(0)) {
                        UserToken storage _user = userTokens[userAddr];

                        uint256 countUserToken = _user.totalToken;

                        uint256 userCommission = userFee * countUserToken;

                        _user.commission += userCommission;
                    }
                }
            }

            balance200 += msg.value;
        }



        
        // if (msg.value > minPric) {
        //     uint256 s = msg.value - minPric;
        //     (bool success, ) = address(msg.sender).call{value: s}("");
        //     require(success, "");
        // }

        if (rand > 0) {
            uint256 _value = (msg.value * 350) / 1000;
            uint256 value = (msg.value * 2) - _value;

            if (msg.value == 250000000) {
                require(balance200 > value, "try another time");
                _sendValue(msg.sender, value);

                balance25 -= value;
            }

            if (msg.value == 25e18) {
                require(balance200 > value, "try another time");
                _sendValue(msg.sender, value);

                balance25 -= value;
            }
            if (msg.value == 50e18) {
                require(balance200 > value, "try another time");
                _sendValue(msg.sender, value);

                balance50 -= value;
            }
            if (msg.value == 100e18) {
                require(balance200 > value, "try another time");
                _sendValue(msg.sender, value);

                balance100 -= value;
            }
            if (msg.value == 200e18) {
                require(balance200 > value, "try another time");
                _sendValue(msg.sender, value);

                balance200 -= value;
            }
        }

        History storage txHistory = txHistorys[msg.sender];

        totalTransaction storage totaltx = listTX[totaltried];
        totaltx.userAmount = msg.value;

        totaltx.userAdress = msg.sender;
        totaltx.userTxSuccess = rand;

        txHistory.deposits.push(
            PlayerDeposit({
                amount: msg.value,
                totalWithdraw: 0,
                wasSuccess: rand,
                time: uint256(block.timestamp)
            })
        );
        //  txHistorys[msg.sender]=History(88,rand,msg.sender,msg.value);
        txHistory.tokenId = 33;
        txHistory.wasSuccess = rand;
        txHistory.owner = msg.sender;
        txHistory.price = msg.value;

        totaltried++;
        emit Deposit(msg.sender, msg.value, rand);
    }

    /*************************************************************************** */
    //                             Transfer Token  :

    function offerPunkForSale(uint256 punkIndex) public reentrancyGuard {
        require(isMarketEnabled, "Market Paused");
        require(defultContract.ownerOf(punkIndex) == msg.sender, "Only owner");
        require(
            (defultContract.getApproved(punkIndex) == address(this) ||
                defultContract.isApprovedForAll(msg.sender, address(this))),
            "Not Approved"
        );
        defultContract.safeTransferFrom(msg.sender, address(this), punkIndex);
        punksOfferedForSale[punkIndex] = Offer(
            true,
            punkIndex,
            msg.sender,
            address(0)
        );

        UserToken storage _userToken = userTokens[msg.sender];

        _userToken.active = true;
        _userToken.tokenIds.push(punkIndex);
        _userToken.totalToken += 1;
        _userToken.ownerToken = msg.sender;

        UserWalletAddressAndTokenCount storage userWallet = userAddress[id];
        userWallet.public_key = msg.sender;
        // userWallet.tokens.push(punkIndex);

        id++;
        totalToken++;

        emit PunkOffered(punkIndex, address(0));
    }

    function punkNoLongerForSale(uint256 punkIndex, uint256 _index)
        public
        reentrancyGuard
    {
        Offer memory offer = punksOfferedForSale[punkIndex];
        require(offer.isForSale == true, "punk is not for sale");
        address seller = offer.seller;
        require(seller == msg.sender, "Only Owner");
        defultContract.safeTransferFrom(address(this), msg.sender, punkIndex);

        punksOfferedForSale[punkIndex] = Offer(
            false,
            punkIndex,
            msg.sender,
            address(0)
        );

        UserToken storage _userToken = userTokens[msg.sender];

        totalToken--;

        _userToken.active = false;
        _userToken.totalToken -= 1;
        _userToken.ownerToken = msg.sender;

        // delete _userToken.tokenIds[_index];

        removeByValue(msg.sender, punkIndex);
        emit PunkNoLongerForSale(punkIndex);
    }

    /*************************************************************************** */

    /*************************************************************************** */
    //                             The Other :

    function find(address _wallet, uint256 value) private returns (uint256) {
        uint256 i = 0;
        while (userTokens[_wallet].tokenIds[i] != value) {
            i++;
        }
        return i;
    }

    function removeByValue(address _wallet, uint256 value) private {
        uint256 i = find(_wallet, value);
        removeByIndex(_wallet, i);
    }

    function removeByIndex(address _wallet, uint256 i) private {
        // while (i<userTokens[_wallet].tokenIds.length-1) {
        //     userTokens[_wallet].tokenIds[i] = userTokens[_wallet].tokenIds[i+1];
        //     i++;
        // }
        // userTokens[_wallet].tokenIds.length--;

        delete userTokens[_wallet].tokenIds[i];
    }

    function getUserTokens(address _walletAddress)
        public
        view
        returns (uint256[] memory)
    {
        UserToken storage _userToken = userTokens[_walletAddress];

        return _userToken.tokenIds;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        _data;
        emit ERC721Received(_operator, _from, _tokenId);
        return 0x150b7a02;
    }

    function _sendValue(address _to, uint256 _value) internal {
        (bool success, ) = payable(address(_to)).call{value: _value}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function _calculateShares(uint256 value)
        internal
        view
        returns (
            uint256 _sellerShare,
            uint256 _feeBOneShare,
            uint256 _feeBTwoShare,
            uint256 _feeBThreeShare,
            uint256 _feeBFourShare
        )
    {
        uint256 totalFeeValue = _fraction(DexFeePercent, 100, value); // fee: 6% of punk price
        _sellerShare = value - totalFeeValue; // 94% of punk price
        _feeBOneShare = _fraction(2, 5, totalFeeValue); // 40% of fee
        _feeBTwoShare = _fraction(1, 10, totalFeeValue); // 10% of Fee
        _feeBThreeShare = _fraction(1, 3, totalFeeValue); // 33.33% of Fee
        _feeBFourShare = _fraction(1, 6, totalFeeValue); // 16.66% of fee
        return (
            _sellerShare,
            _feeBOneShare,
            _feeBTwoShare,
            _feeBThreeShare,
            _feeBFourShare
        );
    }

    function _fraction(
        uint256 devidend,
        uint256 divisor,
        uint256 value
    ) internal pure returns (uint256) {
        return (value.mul(devidend)).div(divisor);
    }

    function withdrawUserCommission() public payable onlyOwner {
        UserToken storage user = userTokens[msg.sender];

        (bool success, ) = msg.sender.call{value: user.commission}("");
        require(success, "withdraw undone");

        userTokens[msg.sender].commission = 0;
    }

    /*************************************************************************** */
    /*************************************************************************** */
    //                             Admin functions:

    function increaseBalance() public payable onlyOwner {
        (bool success, ) = address(this).call{value: msg.value}("");
    }

    function increaseBalance25() public payable onlyOwner {
        balance25 = msg.value;
    }

    function increaseBalance50() public payable onlyOwner {
        balance50 = msg.value;
    }

    function increaseBalance100() public payable onlyOwner {
        balance100 = msg.value;
    }

    function increaseBalance200() public payable onlyOwner {
        balance200 = msg.value;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = owner().call{value: adminFeeAmount}("");
        adminFeeAmount = 0;
        require(success, "withdraw undone");
    }

    function withdrawBalance(uint256 _priceETH) public payable onlyOwner {
        require(address(this).balance > (_priceETH * 1e18), "value inValid");
        (bool success, ) = owner().call{value: _priceETH}("");
        require(success, "withdraw undone");
    }

    // function addWalletToBlockList(address _wallet) public payable onlyOwner {
    //     blockList[_wallet] = true;
    // }

    // function exitWalletBlockList(address _wallet) public payable onlyOwner {
    //     blockList[_wallet] = false;
    // }

    function balaneOf() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function enableMarket() external onlyOwner {
        if (!isMarketEnabled) {
            isMarketEnabled = true;
        }
    }

    function disableMarket() external onlyOwner {
        if (isMarketEnabled) {
            isMarketEnabled = false;
        }
    }

    /*************************************************************************** */
    /*************************************************************************** */
    //                             modifier :

    modifier reentrancyGuard() {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    /***************************************************************************

    /*************************************************************************** */
    //                             Events:

    event AddERC721Contract(address contractAddress);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(
        address indexed from,
        address indexed to,
        uint256 punkIndex
    );
    event PunkOffered(uint256 indexed punkIndex, address indexed toAddress);
    event PunkNoLongerForSale(uint256 indexed punkIndex);
    event ERC721Received(address operator, address _from, uint256 tokenId);
    event Deposit(address indexed addr, uint256 amount, uint256 rand);
}