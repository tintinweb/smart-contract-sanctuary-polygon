// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./random.sol";
import "./SafeMath.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

interface IERC721 {
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

    function isExists(uint256 _tokenId) external returns (bool);
}

contract DoubleOrNothing is ERC721TokenReceiver, Ownable, randoms {
    IERC721 private IERC721s;

    using SafeMath for uint256;

    uint256[] public amounts = [
        5 ether,
        10 ether,
        25 ether,
        50 ether,
        100 ether
    ];

    uint256 gasFeesForLink = 0.02 ether;

    uint256 public balance5;
    bool public balance5Enable = false;
    uint256 public balance10;
    bool public balance10Enable = false;
    uint256 public balance25;
    bool public balance25Enable = false;

    uint256 public balance50;
    bool public balance50Enable = false;
    uint256 public balance100;
    bool public balance100Enable = false;

    uint256 public Double;
    uint256 public Nothing;

    uint256 public successfulAttempt;
    uint256 public holdersPrice;

    IERC721 internal defultContract;

    uint256 public totaltried = 0;
    uint256 public totalToken = 0;
    uint256 public totalValuem = 0;

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
        defultContract = IERC721(address(_defultContract));
    }

    function contributionsInfo(address _addr)
        external
        view
        returns (
            uint256[] memory _amounts_,
            uint256[] memory _totalWithdraws_,
            uint256[] memory _issuccess_
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
            uint256[] memory _amounts_,
            address[] memory _useradress_,
            uint256[] memory _issuccess_
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
    }

    function ApeNoLongerForSale(uint256 apeIndex)
        public
        reentrancyGuard
    {
        Offer memory offer = apesOfferedForSale[apeIndex];
        require(offer.isForSale == true, "ape is not staked.");
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

        _userToken.totalToken -= 1;
   

        removeByValue(msg.sender, apeIndex);
    }

    /*************************************************************************** */
    //                             TRY CHANCE 5 :

    function tryChance5() public payable {
        require(isContract(msg.sender) == false,"you contract !!!!!!! what????");
        require(balance5Enable, "not active 5 matic double or nothing");
        require(msg.value == 5 ether, "Wrong ETH ");

        uint256 _value = msg.value * 2;
        uint256 val = (_value * 35) / 1000;
        uint256 value = _value - val;

        require(balance5 > value, "try another time balnace 5");

        if (totalToken > 0) {
            uint256 usersFee = (msg.value * 35) / 1000;

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

        balance5 += msg.value;
        totalValuem += msg.value;

        uint256 random = random1();

        if (random > 0) {
            Double++;

            successfulAttempt += value;

            UserToken storage user = userTokens[msg.sender];

            user.userDoubleMATIC += value;

            _sendValue(msg.sender, value);
            balance5 -= value;
        }

        if (random == 0) {
            UserToken storage user = userTokens[msg.sender];

            user.userNothingMATIC += msg.value;

            Nothing++;
        }

        History storage txHistory = txHistorys[msg.sender];

        totalTransaction storage totaltx = listTX[totaltried];
        totaltx.userAmount = msg.value;

        totaltx.userAdress = msg.sender;
        totaltx.userTxSuccess = random;

        txHistory.deposits.push(
            PlayerDeposit({
                amount: msg.value,
                totalWithdraw: 0,
                wasSuccess: random,
                time: uint256(block.timestamp)
            })
        );
        txHistory.wasSuccess = random;
        txHistory.owner = msg.sender;
        txHistory.price = msg.value;

        totaltried++;
        emit Deposit(msg.sender, msg.value, random);
    }

    //                             TRY CHANCE 10 :

    function tryChance10() public payable {
        require(isContract(msg.sender) == false,"you contract !!!!!!! what????");
        require(balance10Enable, "not active 10 matic double or nothing");
        require(msg.value == 10 ether, "Wrong ETH ");

        uint256 _value = msg.value * 2;
        uint256 val = (_value * 35) / 1000;
        uint256 value = _value - val;

        require(balance10 > value, "try another time balnace 10");

        if (totalToken > 0) {
            uint256 usersFee = (msg.value * 35) / 1000;

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

        balance10 += msg.value;
        totalValuem += msg.value;

        uint256 random = random2();

        if (random > 0) {
            Double++;

            successfulAttempt += value;

            UserToken storage user = userTokens[msg.sender];

            user.userDoubleMATIC += value;

            _sendValue(msg.sender, value);
            balance10 -= value;
        }

        if (random == 0) {
            UserToken storage user = userTokens[msg.sender];

            user.userNothingMATIC += msg.value;

            Nothing++;
        }

        History storage txHistory = txHistorys[msg.sender];

        totalTransaction storage totaltx = listTX[totaltried];
        totaltx.userAmount = msg.value;

        totaltx.userAdress = msg.sender;
        totaltx.userTxSuccess = random;

        txHistory.deposits.push(
            PlayerDeposit({
                amount: msg.value,
                totalWithdraw: 0,
                wasSuccess: random,
                time: uint256(block.timestamp)
            })
        );
        txHistory.wasSuccess = random;
        txHistory.owner = msg.sender;
        txHistory.price = msg.value;

        totaltried++;
        emit Deposit(msg.sender, msg.value, random);
    }

    //                             TRY CHANCE 25 :

    function tryChance25() public payable {
        require(isContract(msg.sender) == false,"you contract !!!!!!! what????");
        require(balance25Enable, "not active 25 matic double or nothing");
       require(msg.value == 25 ether, "Wrong ETH ");

        uint256 _value = msg.value * 2;
        uint256 val = (_value * 35) / 1000;
        uint256 value = _value - val;

        require(balance25 > value, "try another time balnace 25");

        if (totalToken > 0) {
            uint256 usersFee = (msg.value * 35) / 1000;

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

        balance25 += msg.value;
        totalValuem += msg.value;

        uint256 random = random3();

        if (random > 0) {
            Double++;

            successfulAttempt += value;

            UserToken storage user = userTokens[msg.sender];

            user.userDoubleMATIC += value;

            _sendValue(msg.sender, value);
            balance25 -= value;
        }

        if (random == 0) {
            UserToken storage user = userTokens[msg.sender];

            user.userNothingMATIC += msg.value;

            Nothing++;
        }

        History storage txHistory = txHistorys[msg.sender];

        totalTransaction storage totaltx = listTX[totaltried];
        totaltx.userAmount = msg.value;

        totaltx.userAdress = msg.sender;
        totaltx.userTxSuccess = random;

        txHistory.deposits.push(
            PlayerDeposit({
                amount: msg.value,
                totalWithdraw: 0,
                wasSuccess: random,
                time: uint256(block.timestamp)
            })
        );
        txHistory.wasSuccess = random;
        txHistory.owner = msg.sender;
        txHistory.price = msg.value;

        totaltried++;
        emit Deposit(msg.sender, msg.value, random);
    }

    //                             TRY CHANCE 50 :

    function tryChance50() public payable {
      require(isContract(msg.sender) == false,"you contract !!!!!!! what????");
        require(balance50Enable, "not active 50 matic double or nothing");
        require(msg.value == 50 ether, "Wrong ETH ");

        uint256 _value = msg.value * 2;
        uint256 val = (_value * 35) / 1000;
        uint256 value = _value - val;

        require(balance50 > value, "try another time balnace 50");

        if (totalToken > 0) {
            uint256 usersFee = (msg.value * 35) / 1000;

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

        balance50 += msg.value;
        totalValuem += msg.value;

        uint256 random = random4();

        if (random > 0) {
            Double++;

            successfulAttempt += value;

            UserToken storage user = userTokens[msg.sender];

            user.userDoubleMATIC += value;

            _sendValue(msg.sender, value);
            balance50 -= value;
        }

        if (random == 0) {
            UserToken storage user = userTokens[msg.sender];

            user.userNothingMATIC += msg.value;

            Nothing++;
        }

        History storage txHistory = txHistorys[msg.sender];

        totalTransaction storage totaltx = listTX[totaltried];
        totaltx.userAmount = msg.value;

        totaltx.userAdress = msg.sender;
        totaltx.userTxSuccess = random;

        txHistory.deposits.push(
            PlayerDeposit({
                amount: msg.value,
                totalWithdraw: 0,
                wasSuccess: random,
                time: uint256(block.timestamp)
            })
        );
        txHistory.wasSuccess = random;
        txHistory.owner = msg.sender;
        txHistory.price = msg.value;

        totaltried++;
        emit Deposit(msg.sender, msg.value, random);
    }

    //                             TRY CHANCE 100 :

    function tryChance100() public payable {
     require(isContract(msg.sender) == false,"you contract !!!!!!! what????");
        require(balance100Enable, "not active 100 matic double or nothing");
        require(msg.value == 100 ether, "Wrong ETH ");
        uint256 _value = msg.value * 2;
        uint256 val = (_value * 35) / 1000;
        uint256 value = _value - val;

        require(balance100 > value, "try another time balnace 0.0025");

        if (totalToken > 0) {
            uint256 usersFee = (msg.value * 35) / 1000;

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

        balance100 += msg.value;
        totalValuem += msg.value;

        uint256 random = random5();

        if (random > 0) {
            Double++;

            successfulAttempt += value;

            UserToken storage user = userTokens[msg.sender];

            user.userDoubleMATIC += value;

            _sendValue(msg.sender, value);
            balance100 -= value;
        }

        if (random == 0) {
            UserToken storage user = userTokens[msg.sender];

            user.userNothingMATIC += msg.value;

            Nothing++;
        }

        History storage txHistory = txHistorys[msg.sender];

        totalTransaction storage totaltx = listTX[totaltried];
        totaltx.userAmount = msg.value;

        totaltx.userAdress = msg.sender;
        totaltx.userTxSuccess = random;

        txHistory.deposits.push(
            PlayerDeposit({
                amount: msg.value,
                totalWithdraw: 0,
                wasSuccess: random,
                time: uint256(block.timestamp)
            })
        );
        txHistory.wasSuccess = random;
        txHistory.owner = msg.sender;
        txHistory.price = msg.value;

        totaltried++;
        emit Deposit(msg.sender, msg.value, random);
    }

    /*************************************************************************** */

    /*************************************************************************** */
    //                             The Other :

    function amountExists(uint256 num) public view returns (bool) {
        for (uint8 i = 0; i < amounts.length; i++) {
            if (amounts[i] == num) {
                return true;
            }
        }
        return false;
    }

    function find(address _wallet, uint256 value) private view returns (uint256) {
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

    function withdrawUserCommission() public payable {
        UserToken storage user = userTokens[msg.sender];

        (bool success, ) = msg.sender.call{value: user.commission}("");
        require(success, "withdraw undone");

        userTokens[msg.sender].commission = 0;
    }

    /*************************************************************************** */
    /*************************************************************************** */
    //                             Admin functions:


    function increaseBalance() public payable onlyOwner {
        // (bool success, ) = address(this).call{value: msg.value}("");
    }

    function increaseBalance5(uint256 _price) public onlyOwner {
        balance5 = _price;
    }
     function increaseBalance25(uint256 _price) public onlyOwner {
        balance25 = _price;
    }


    function increasebalance10(uint256 _price) public onlyOwner {
        balance10 = _price;
    }

    function increaseBalance100(uint256 _price) public onlyOwner {
        balance100 = _price;
    }

    function increasebalance50(uint256 _price) public onlyOwner {
        balance50 = _price;
    }

    function _enableBalance5() external onlyOwner {
        if (!balance5Enable) {
            balance5Enable = true;
        }else{
            balance5Enable = false;
        }
    }

  

    function _enableBalance10() external onlyOwner {
        if (!balance10Enable) {
            balance10Enable = true;
        }else{
            balance10Enable = false;
        }
    }

    function _enableBalance25() external onlyOwner {
        if (!balance25Enable) {
            balance25Enable = true;
        }else{
            balance25Enable = false;
        }
    }


    function _enableBalance50() external onlyOwner {
        if (!balance50Enable) {
            balance50Enable = true;
        }else{
            balance50Enable = false;
        }
    }

 
    function _enableBalance100() external onlyOwner {
        if (!balance100Enable) {
            balance100Enable = true;
        }else{
            balance100Enable = false;
        }
    }

    

    function withdraw(uint256 _priceETH) public onlyOwner {
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
        }else{
            isMarketEnabled = false;
        }
    }

   
    /*************************************************************************** */

    /*************************************************************************** */
    //                             Service:
    function isContract(address _addr)
        internal
        view
        returns (bool addressCheck)
    {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        } // solhint-disable-line
        addressCheck = size > 0;
    }

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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event ERC721Received(address operator, address _from, uint256 tokenId);
    event Deposit(address indexed addr, uint256 amount, uint256 rand);
}