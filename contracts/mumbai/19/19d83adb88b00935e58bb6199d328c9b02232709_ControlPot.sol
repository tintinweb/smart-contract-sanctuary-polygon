/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library myLibrary {
    struct bidPrice {
        uint256 bidOption;
        uint256 variable1;
        uint256 variable2;
    }
    struct expiryTimeInfo {
        uint256 expiryOption;
        uint256 startTime;
        uint256 decreaseBy;
        uint256 minimumTime;
    }
    struct createPotValue {
        address topOwner;
        address ownerOfTournament;
        // address potToken;
        bool isNative;
        // uint256 potAmount;\
        uint256 tokenID;
        address bidToken;
        bidPrice bid;
        address[] toAddress;
        uint256[] toPercent;
        expiryTimeInfo expiryTime;
        bool priorityPool;
        uint256 toPreviousFee;
    }
}

contract Pot {

    using SafeMath for uint256;

    // address public potToken;
    // uint256 public potAmount = 0;
    uint256 public tokenID;
    address public bidToken;
    uint256 public bidAmount;
    bool public priorityPool;
    bool public isClaim;
    uint256 public createdDate;
    uint256 public timeUntilExpiry;   
    address public ownerOfTournament;
    address public lastBidWinner;
    uint256 public lengthOfBidDistribution = 0;

    uint256 public toOwnerFee = 3;
    uint256 public percent = 100;
    address public toPreviousBidder;
    uint256 public toPreviousBidderFee;

    uint256 private winnerClaimAllowTime = 600; // 2851200000; // 33 days
    uint256 private createClaimAllowTime = 720; // 5702400000; // 66 days
    address public topOwner;

    uint256 public bidOption;
    uint256 public bidVariable1;
    uint256 public bidVariable2;
    bool public isNative;
    uint256 public claimedDate;

    uint256 public expirationTime;
    uint256 public expExpiryOption;
    uint256 public expDecreaseBy;
    uint256 public expMinimumTime;

    IERC20 _token;    
    IERC721 erc721Token;

    struct bidDistributionInfo {
        address toAddress;
        uint256 percentage;
    }

    mapping(uint256 => bidDistributionInfo) public bidInfo;

    modifier onlyOwner() {
        require(msg.sender == ownerOfTournament, "Not onwer");
        _;
    }

    constructor() {
        erc721Token = IERC721(address(0x2B8E10F27CD887933449B0De0F60Cb79a1338149));
    }

    function setTopOwner(address newTopOwner) public {
        require(topOwner == msg.sender, "Error: you can not change Top Owner address!");
        topOwner = newTopOwner;
    }

    function calcBidAmount(uint256 _bidOption, uint256 _variable1, uint256 _variable2) internal {
        if(_bidOption == 1) {
            bidAmount = _variable1;
        } else if (_bidOption == 2) {
            bidAmount = bidAmount + bidAmount.mul(_variable2).div(percent);
        }
    }

    function initialize(myLibrary.createPotValue memory sValue) external {
        if (lengthOfBidDistribution > 0) {
            require(topOwner == msg.sender, "Error: you can not change initial variable");
        }
        bidToken = sValue.bidToken;
        isNative = sValue.isNative;        
        _token = IERC20(address(bidToken));
        lengthOfBidDistribution = sValue.toAddress.length;
        for(uint256 i = 0; i < sValue.toAddress.length; i++) {
            bidInfo[i].toAddress = sValue.toAddress[i];
            bidInfo[i].percentage = sValue.toPercent[i];
        }
        priorityPool = sValue.priorityPool;
        createdDate = block.timestamp;

        timeUntilExpiry = createdDate + sValue.expiryTime.startTime;  
        expExpiryOption = sValue.expiryTime.expiryOption;      
        expirationTime = sValue.expiryTime.startTime;
        expDecreaseBy = sValue.expiryTime.decreaseBy;
        expMinimumTime = sValue.expiryTime.minimumTime;

        tokenID = sValue.tokenID;
        lastBidWinner = sValue.ownerOfTournament;
        toPreviousBidderFee = sValue.toPreviousFee;
        ownerOfTournament = sValue.ownerOfTournament;

        topOwner = sValue.topOwner;    
        
        bidOption = sValue.bid.bidOption;  
        bidVariable1 = sValue.bid.variable1;  
        bidVariable2 = sValue.bid.variable2; 
        isClaim = false;

        if(bidOption == 1) {
            bidAmount = bidVariable1;
        } else if (bidOption == 2) {
            bidAmount = bidVariable1;
        }
    }
               
    function bid() public payable returns (uint256) {
        require(timeUntilExpiry > block.timestamp, "You cannot bid! Because this pot is closed biding!");
        require(msg.value > 0, "Insufficinet value");
        require(msg.value == bidAmount, "Your bid amount will not exact!");   

        toPreviousBidder = lastBidWinner;

        uint256 value = msg.value;
        lastBidWinner = msg.sender;

        if(expExpiryOption == 2 && expirationTime > expMinimumTime) {
            expirationTime -= expDecreaseBy;
        }

        uint256 onwerFee = bidAmount.mul(toOwnerFee).div(percent);        
        payable(address(topOwner)).transfer(onwerFee);    
        value = value - onwerFee;

        uint256 previousBidderFee = bidAmount.mul(toPreviousBidderFee).div(percent);        
        payable(address(toPreviousBidder)).transfer(previousBidderFee);    
        value = value - previousBidderFee;

        for (uint i = 0; i < lengthOfBidDistribution; i++) {
            uint256 bidFee = bidAmount.mul(bidInfo[i].percentage).div(percent);
            payable(address(bidInfo[i].toAddress)).transfer(bidFee);
            value = value - bidFee;
        }

        uint256 createdBid = block.timestamp;
        timeUntilExpiry = createdBid + expirationTime;
             
        // potAmount = address(this).balance;
        calcBidAmount(bidOption, bidVariable1, bidVariable2);
        return bidAmount;
    }
    function bidERC20() public returns (uint256) {
        require(timeUntilExpiry > block.timestamp, "You cannot bid! Because this pot is closed biding!");

        toPreviousBidder = lastBidWinner;

        uint256 value = bidAmount;
        lastBidWinner = msg.sender;

        if(expExpiryOption == 2 && expirationTime > expMinimumTime) {
            expirationTime -= expDecreaseBy;
        }

        uint256 onwerFee = bidAmount.mul(toOwnerFee).div(percent);        
        _token.transferFrom(msg.sender, topOwner, onwerFee);
        value = value - onwerFee;

        uint256 previousBidderFee = bidAmount.mul(toPreviousBidderFee).div(percent);  
        _token.transferFrom(msg.sender, toPreviousBidder, previousBidderFee);   
        value = value - previousBidderFee;

        for (uint i = 0; i < lengthOfBidDistribution; i++) {
            uint256 bidFee = bidAmount.mul(bidInfo[i].percentage).div(percent);        
            _token.transferFrom(msg.sender, bidInfo[i].toAddress, bidFee);   
            value = value - bidFee;
        }
        _token.transferFrom(msg.sender, address(this), value); 
        uint256 createdBid = block.timestamp;
        timeUntilExpiry = createdBid + expirationTime;
             
        // potAmount = _token.balanceOf(address(this));
        calcBidAmount(bidOption, bidVariable1, bidVariable2);
        return bidAmount;
    }

    function getLifeTime() public view returns (uint256) {
        if(timeUntilExpiry > block.timestamp){
            uint256 lifeTime = timeUntilExpiry - block.timestamp;
            return lifeTime;  
        } else {
            return 0;
        }
    }

    function claim() public returns (uint256) {
        address claimAvailableAddress;
        
        if(block.timestamp < timeUntilExpiry) {
            claimAvailableAddress = 0x0000000000000000000000000000000000000000;
        } else if (timeUntilExpiry < block.timestamp && block.timestamp < timeUntilExpiry + winnerClaimAllowTime) {
            claimAvailableAddress = lastBidWinner;
        } else if (timeUntilExpiry + winnerClaimAllowTime < block.timestamp && block.timestamp < timeUntilExpiry + createClaimAllowTime) {
            claimAvailableAddress = ownerOfTournament;
        } else {
            claimAvailableAddress = topOwner;
        }
        require(msg.sender == claimAvailableAddress, "You cannot claim!");
        erc721Token.approve(msg.sender, tokenID);
        erc721Token.transferFrom(address(this), msg.sender, tokenID);
        claimedDate = block.timestamp;
        return address(this).balance;
    }
    modifier checkAllowance(uint256 amount) {
        require(_token.allowance(msg.sender, address(this)) >= amount, "Allowance Error");
        _;
    }
    // modifier checkAllowanceNFT(address owner) {
    //     require(_token.allowance(msg.sender, address(this)) >= amount, "Allowance Error");
    //     _;
    // }
    // function depositERC20Token() external payable checkAllowance(potAmount) {
    //     require(msg.value > 0, "you can deposit more than 0!");
    //     require(msg.sender == ownerOfTournament, "You cannot deposit because  you are not owner of this tournament");
    //     require(potAmount > 0, "Insufficinet value");
    //     if(isNative == false) {
    //         _token.transferFrom(msg.sender, address(this), potAmount);
    //     }
    //     uint256 balance = address(msg.sender).balance;
    //     calcBidAmount(bidOption, bidVariable1, bidVariable2);
    //     require(balance >= msg.value, "Insufficient balance or allowance");
    // }
    function depositNFT() external {
        address owner = erc721Token.ownerOf(tokenID);
        require(owner == msg.sender, "you are not token owner!");
        erc721Token.approve(address(this), tokenID);
        erc721Token.transferFrom(owner, address(this), tokenID);
    }
    function depositToken() external payable {
        require(msg.value > 0, "you can deposit more than 0!");
        require(msg.sender == ownerOfTournament, "You cannot deposit because  you are not owner of this tournament");
        // require(potAmount > 0, "Insufficinet value");
        uint256 balance = address(msg.sender).balance;
        calcBidAmount(bidOption, bidVariable1, bidVariable2);
        require(balance >= msg.value, "Insufficient balance or allowance");
    }
}

pragma solidity >=0.7.0 <0.9.0;

contract ControlPot {

    event Deployed(address);
    event Received(address, uint256);
    address public topOwner;
    address[] public allTournaments;
    address[] public bidDistributionAddress;

    uint256 public toOwnerFee = 3;
    uint256 public percent = 100;
    IERC721 erc721Token;

    address[] public tokenList;
      
    uint256 private bidPercent = 0;

    constructor() {
        topOwner = msg.sender;
        erc721Token = IERC721(address(0x2B8E10F27CD887933449B0De0F60Cb79a1338149));
    }

    struct bidPrice {
        uint256 bidOption;
        uint256 variable1;
        uint256 variable2;
    }
    struct expiryTimeInfoVal {
        uint256 expiryOption;
        uint256 startTime;
        uint256 decreaseBy;
        uint256 minimumTime;
    }
    modifier onlyOwner() {
        require(msg.sender == topOwner, "Not onwer");
        _;
    }
    function addToken(address _token) external onlyOwner{
        tokenList.push(_token);
    }
    function removeToken(uint256 _index) external onlyOwner{
        delete tokenList[_index];
    }
    function getTokenList() external view returns (address[] memory) {
        return tokenList;
    }
    function allTournamentsLength() external view returns (uint256) {
        return allTournaments.length;
    }
    function setTopOwner(address newTopOwner) public {
        require(topOwner == msg.sender, "Error: you can not change Top Owner address!");
        topOwner = newTopOwner;
    }
    function setToOwnerFee(uint256 newToOwnerFee) public {
        require(topOwner == msg.sender, "Error: you can not change Top Owner address!");
        toOwnerFee = newToOwnerFee;
    }
    function ownerCheck(uint256 tokenID) public view returns(address) {
        address owner = erc721Token.ownerOf(tokenID);
        return owner;
    }
    function createPot(uint256 _tokenID, uint256 _bidTokenIndex, bool _isNative, bidPrice memory _bid, address[] memory _toAddress, uint256[] memory _toPercent, expiryTimeInfoVal memory _expirationTime, bool _priorityPool, uint256 _toPreviousFee) external returns (address pair) {
        require(_toAddress.length == _toPercent.length, "Length of address and percentage is not match"); 
        for (uint256 i = 0; i < _toPercent.length; i++) {
            bidPercent += _toPercent[i];
        }
        require(bidPercent == (percent - toOwnerFee - _toPreviousFee), "Fee is not 100%!");
        bytes memory bytecode = type(Pot).creationCode;
        myLibrary.createPotValue memory cValue; 
        
        cValue.topOwner = topOwner;
        cValue.tokenID = _tokenID;
        cValue.ownerOfTournament = msg.sender;
        // cValue.potToken = tokenList[_potTokenIndex];
        // cValue.potAmount = _potAmount;
        cValue.bidToken = tokenList[_bidTokenIndex];
        cValue.bid.bidOption = _bid.bidOption;
        cValue.bid.variable1 = _bid.variable1;
        cValue.bid.variable2 = _bid.variable2;
        cValue.toAddress = _toAddress;
        cValue.isNative = _isNative;
        cValue.toPercent = _toPercent;
        cValue.expiryTime.expiryOption = _expirationTime.expiryOption;
        cValue.expiryTime.startTime = _expirationTime.startTime;
        cValue.expiryTime.decreaseBy = _expirationTime.decreaseBy;
        cValue.expiryTime.minimumTime = _expirationTime.minimumTime;
        cValue.priorityPool = _priorityPool;
        cValue.toPreviousFee = _toPreviousFee;

        bytes32 salt = keccak256(abi.encodePacked(tokenList[_bidTokenIndex], _bid.variable1, _toAddress, _toPercent, cValue.expiryTime.startTime, cValue.expiryTime.decreaseBy, cValue.expiryTime.minimumTime, _priorityPool, _toPreviousFee));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        allTournaments.push(pair);
        Pot(pair).initialize(cValue);
        emit Deployed(pair);
        bidPercent = 0;
        return pair;
    }
}