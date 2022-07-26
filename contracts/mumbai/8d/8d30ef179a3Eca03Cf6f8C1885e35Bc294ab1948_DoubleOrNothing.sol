/**
 *Submitted for verification at polygonscan.com on 2022-07-25
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

    uint256 public balance25;
    uint256 public balance50;
    uint256 public balance100;
    uint256 public balance200;

    uint256 public Double;
    uint256 public Nothing;

    uint256 public successfulAttempt;
    uint256 public holdersPrice;

    TMEEBIT internal defultContract;

    uint256 public totaltried = 0;
    uint256 public totalToken = 0;
    uint256 public totalValuem = 0;

    uint256 public adminFeeAmount;

    uint256 private id = 0;

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
        uint256 userDoubleMATIC;
        uint256 userNothingMATIC;
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
        uint256 apeIndex;
        address seller;
        address onlySellTo;
    }

    mapping(uint256 => totalTransaction) public listTX;

    mapping(address => History) public txHistorys;

    mapping(uint256 => Offer) public apesOfferedForSale;

    mapping(address => address) public contractAddress;

    mapping(address => UserToken) public userTokens;

    mapping(uint256 => UserWalletAddressAndTokenCount) public userAddress;

    constructor(address _defultContract) {
        defultContract = TMEEBIT(address(_defultContract));
    }

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
        uint256 rand;

        require(
            msg.value == 2500000000000000 ||
                msg.value == 25e18 ||
                msg.value == 50e18 ||
                msg.value == 100e18 ||
                msg.value == 200e18,
            "value "
        );

        uint256 fee = (msg.value * 350) / 1000;
        uint256 adminPrice = (fee * 150) / 1000;

        adminFeeAmount += adminPrice;


        if (totalToken > 0) {
            uint256 usersFee = (fee * 20) / 1000;

            uint256 userFee = usersFee / totalToken;

            holdersPrice += usersFee;

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




        if (msg.value == 2500000000000000) {
            rand = random1();

            balance25 += msg.value;
        }

        if (msg.value == 25e18) {
            rand = random1();
            balance25 += msg.value;
        }

        if (msg.value == 50e18) {
            rand = random2();

            balance50 += msg.value;
        }

        if (msg.value == 100e18) {
            rand = random3();


            balance100 += msg.value;
        }

        if (msg.value == 200e18) {
            rand = random4();


            balance200 += msg.value;
        }

        totalValuem += msg.value;

        if (rand > 0) {
            Double++;
            uint256 _value = msg.value * 2;
            uint256 val = (_value * 350) / 1000;

            uint256 value = _value - val;

            successfulAttempt += value;

            UserToken storage user = userTokens[msg.sender];

            user.userDoubleMATIC += value;

            if (msg.value == 2500000000000000) {
                require(balance25 > value, "try another time balnace 0.0025");

                _sendValue(msg.sender, value);
                balance25 -= value;
            }

            if (msg.value == 25e18) {
                require(balance25 > value, "try another time balance 25");
                _sendValue(msg.sender, value);
                balance25 -= value;
            }

            if (msg.value == 50e18) {
                require(balance50 > value, "try another time balance 50");
                _sendValue(msg.sender, value);

                balance50 -= value;
            }

            if (msg.value == 100e18) {
                require(balance100 > value, "try another time balance 100");
                _sendValue(msg.sender, value);

                balance100 -= value;
            }

            if (msg.value == 200e18) {
                require(balance200 > value, "try another time balance 200");
                _sendValue(msg.sender, value);

                balance200 -= value;
            }
        }

        if (rand == 0) {
            UserToken storage user = userTokens[msg.sender];

            user.userNothingMATIC += msg.value;

            Nothing++;
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

    function offerApeForSale(uint256 apeIndex) public reentrancyGuard {
        require(isMarketEnabled, "Market Paused");
        require(defultContract.ownerOf(apeIndex) == msg.sender, "Only owner");
        require(
            (defultContract.getApproved(apeIndex) == address(this) ||
                defultContract.isApprovedForAll(msg.sender, address(this))),
            "Not Approved"
        );
        defultContract.safeTransferFrom(msg.sender, address(this), apeIndex);
        apesOfferedForSale[apeIndex] = Offer(
            true,
            apeIndex,
            msg.sender,
            address(0)
        );

        UserToken storage _userToken = userTokens[msg.sender];

        _userToken.active = true;
        _userToken.tokenIds.push(apeIndex);
        _userToken.totalToken += 1;
        _userToken.ownerToken = msg.sender;

        UserWalletAddressAndTokenCount storage userWallet = userAddress[
            totalToken
        ];
        userWallet.public_key = msg.sender;
        // userWallet.tokens.push(apeIndex);

        id++;
        totalToken++;

        emit ApeOffered(apeIndex, address(0));
    }

    function ApeNoLongerForSale(uint256 apeIndex, uint256 _index)
        public
        reentrancyGuard
    {
        Offer memory offer = apesOfferedForSale[apeIndex];
        require(offer.isForSale == true, "punk is not for sale");
        address seller = offer.seller;
        require(seller == msg.sender, "Only Owner");
        defultContract.safeTransferFrom(address(this), msg.sender, apeIndex);

        apesOfferedForSale[apeIndex] = Offer(
            false,
            apeIndex,
            msg.sender,
            address(0)
        );

        UserToken storage _userToken = userTokens[msg.sender];

        totalToken--;

        _userToken.active = false;
        _userToken.totalToken -= 1;
        _userToken.ownerToken = msg.sender;
        _userToken.userDoubleMATIC = 0;
        _userToken.userNothingMATIC = 0;

        // delete _userToken.tokenIds[_index];

        removeByValue(msg.sender, apeIndex);
        emit _ApeNoLongerForSale(apeIndex);
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
        require(address(this).balance > _value, "try another time");
        (bool success, ) = payable(address(_to)).call{value: _value}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
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

    function increaseBalance25(uint256 _price) public onlyOwner {
        balance25 += _price;
    }

    function increaseBalance50(uint256 _price) public onlyOwner {
        balance50 += _price;
    }

    function increaseBalance100(uint256 _price) public onlyOwner {
        balance100 += _price;
    }

    function increaseBalance200(uint256 _price) public onlyOwner {
        balance200 += _price;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = owner().call{value: adminFeeAmount}("");
        adminFeeAmount = 0;
        require(success, "withdraw undone");
    }

    function withdrawBalance(uint256 _priceETH) public payable onlyOwner {
        require(address(this).balance >= (_priceETH), "value inValid");
        (bool success, ) = owner().call{value: _priceETH}("");
        require(success, "withdraw undone");
    }

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
        uint256 apeIndex
    );
    event ApeOffered(uint256 indexed apeIndex, address indexed toAddress);
    event _ApeNoLongerForSale(uint256 indexed apeIndex);
    event ERC721Received(address operator, address _from, uint256 tokenId);
    event Deposit(address indexed addr, uint256 amount, uint256 rand);
}