/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

/**
 *Submitted for verification at polygonscan.com on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Counters {
    struct Counter {
        uint256 _value; 
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

interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);


    function totalSupply() external view returns (uint);


    function balanceOf(address account) external view returns (uint);

    
    function transfer(address to, uint amount) external returns (bool);

   
    function allowance(address owner, address spender) external view returns (uint);

    
    function approve(address spender, uint amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

library Math {
    enum Rounding {
        Down, 
        Up, 
        Zero 
    }


    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            
            uint256 prod0; 
            uint256 prod1; 
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            if (prod1 == 0) {
                return prod0 / denominator;
            }

            require(denominator > prod1);

            
            uint256 remainder;
            assembly {
                remainder := mulmod(x, y, denominator)

                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }


            uint256 twos = denominator & (~denominator + 1);
            assembly {
                denominator := div(denominator, twos)

                prod0 := div(prod0, twos)

                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

           
            uint256 inverse = (3 * denominator) ^ 2;

            
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse;
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 

            
            result = prod0 * inverse;
            return result;
        }
    }






    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }


    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }


    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }


    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;


    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }


    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }


    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }


    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(_msgSender());
    }


    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }


    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.1;

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        if (returndata.length > 0) {

            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }   
}

pragma solidity ^0.8.0;

interface IERC721Receiver {
   
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity ^0.8.0;


abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

   
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);


    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    function balanceOf(address owner) external view returns (uint256 balance);


    function ownerOf(uint256 tokenId) external view returns (address owner);


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

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    
    function approve(address to, uint256 tokenId) external;

    
    function setApprovalForAll(address operator, bool _approved) external;

   
    function getApproved(uint256 tokenId) external view returns (address operator);

    
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC721Metadata is IERC721 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }


    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }


    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }


    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }


    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }


    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }


    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }


    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }


    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

   
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        owner = ERC721.ownerOf(tokenId);

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        delete _tokenApprovals[tokenId];

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

   
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

   
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, 
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}


interface I1InchAggregatorV5 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(
        address executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

pragma solidity ^0.8.7;

contract UnitDCA is ERC721, Ownable {
    using Counters for Counters.Counter;

    event Mint(uint tokenId, address investorAddress, uint amount);
    event Swap(uint tokenId, address fromToken, address toToken, uint returnAmount, uint spentAmount);
    event TakeProfit(uint tokenId, address fromToken, address toToken, int profit);

    enum SwapOptions { Investing, Fixing }

    struct Investor {
        address ownerAddress;
        Balance USDT;
        TokenInfo MATIC;
        TokenInfo BTC;
        TokenInfo ETH;
        TokenInfo LINK;
    }

    struct TokenInfo{
        uint limitInvestAmount;
        uint totalInvestedAmount;
        uint tokenAmount;
        uint dailySwapsAmount;
        uint dayLastTx;
    }

    struct Balance {
        uint tokenAmount;
    }

    struct Token {
        uint256 id;
        address owner;
    }

    struct Pair {
        uint tokenId;
        uint amount;                
        uint amountWithCommission;  
    }
    
    address public oneInchAggregationRouter;

    mapping(uint => Investor) public investors;
    mapping(uint => uint) public investPool;
    mapping(address => uint) private _mintCount;

    Token[] private tokens;
    
    Balance public ownerCommisionAmount;

    Counters.Counter public tokenIdCounter;

    uint private deploymentDate;
    uint private dailySwapsAmount;

    uint constant public MINIMUM_VALUE = 0; 
    uint constant public MINT_LIMIT = 3; 
    uint constant public TOTAL_SUPPLY = 500; 
    uint constant public WITHDRAW_FEE = 10000;
    uint constant private ACCURACY = 10**21;

    IERC20 constant USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IERC20 constant WMATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270); 
    IERC20 constant WBTC = IERC20(0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6); 
    IERC20 constant WETH = IERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    IERC20 constant LINK = IERC20(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39);

    address private commissionWallet;
    address private blackWallet;
    
    constructor(address _oneInchAggregationRouter, address _ownerWallet, address _commissionWallet, address _blackWallet) ERC721("Unit DCA", "Unit DCA"){
        oneInchAggregationRouter = _oneInchAggregationRouter;
        _transferOwnership(_ownerWallet);
        commissionWallet = _commissionWallet;
        blackWallet = _blackWallet;
        deploymentDate = block.timestamp;
    }

    modifier onlyBlackWallet() {
        require(msg.sender == blackWallet, "Access is closed.");
        _;
    }

    modifier onlyCommissionWallet() {
        require(msg.sender == commissionWallet, "Access is closed.");
        _;
    }

    function setOwnerWallet(address _ownerWallet) external onlyBlackWallet {
        require(_ownerWallet != address(0), "Zero address error.");
        _transferOwnership(_ownerWallet);
    }


    function setCommissionWallet(address _commissionWallet) external onlyBlackWallet {
        require(_commissionWallet != address(0), "Zero address error.");
        commissionWallet = _commissionWallet;
    }
    

    function mintNFT(uint _amount, address _to) external {
        require(_mintCount[_to] <= MINT_LIMIT, "You can mint only 1 NFT");
        require(tokenIdCounter.current() < TOTAL_SUPPLY, "Max supply minted");
        require(_amount >= MINIMUM_VALUE, "The minimum deposit is 30 USDT");

        uint256 tokenId = tokenIdCounter.current();
        tokenIdCounter.increment();

        investors[tokenId].ownerAddress = _to;

        investors[tokenId].USDT.tokenAmount = _amount;

        investPool[tokenId] = _amount;

        _updateInvestPool(tokenId, _amount, true);

        Token memory _newToken = Token(
            tokenId,
            _to
        );

        _safeMint(_to, tokenId);
        _mintCount[_to] += 1;

        tokens.push(_newToken);

        require(USDT.transferFrom(msg.sender, address(this), _amount), "Deposit USDT failed");
       
        emit Mint(tokenId, _to, _amount);
    }
    

    function deposit(uint _tokenId, uint _amount) external {
        require(ownerOf(_tokenId) != address(0), "Zero address error");
        require(_amount > 0, "You can deposit more than 0 usdt");

        require(USDT.transferFrom(msg.sender, address(this), _amount), "Deposit USDT failed");

        investPool[_tokenId] += _amount;

        investors[_tokenId].USDT.tokenAmount += _amount;
    }
        

    function getOwnedTokenIds(address _user) public view returns (uint[] memory) {
        uint[] memory result = new uint[](_balanceOfNFT(_user));
        uint counter = 0;
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i].owner == _user) {
                result[counter] = tokens[i].id;
                counter++;
            }
        }
        return result;
    }


    function _balanceOfNFT(address _user) private view returns (uint) {
            uint counter = 0;
            for (uint i = 0; i < tokens.length; i++) {
                if (tokens[i].owner == _user) {
                    counter++;
                }
            }
            return counter;
        }


    function withdrawUSDTFunds(uint _tokenId, uint _withdrawAmount, bytes[] calldata _txs) external onlyOwner{
        
        uint length = _txs.length;  

        for(uint i=0; i<length; i++){
            uint delta;
            (
                uint returnAmount,
                uint spentAmount,
                address srcToken,
                address dstToken
            ) = _swap(_txs[i]);
            uint currentInvested = _getTotalInvestedAmount(_tokenId, srcToken);
        
            bool numberSign;

            if (currentInvested <= returnAmount){
                delta = returnAmount - currentInvested;
                investPool[_tokenId] += delta;
                numberSign = true;
            } else {
                delta = currentInvested - returnAmount;
                investPool[_tokenId] -= delta;
                numberSign = false;
            }
            _updateTokenInfo(_tokenId, srcToken, dstToken, returnAmount, spentAmount, 0, true, SwapOptions.Fixing);
        }

        if(_withdrawAmount <= investors[_tokenId].USDT.tokenAmount){
            investPool[_tokenId] -= _withdrawAmount;
            require(USDT.transfer(investors[_tokenId].ownerAddress, (_withdrawAmount - WITHDRAW_FEE)), "Withdraw USDT failed");
            investors[_tokenId].USDT.tokenAmount -= _withdrawAmount;

        } else {
            investPool[_tokenId] -= investors[_tokenId].USDT.tokenAmount;
            require(USDT.transfer(investors[_tokenId].ownerAddress, (investors[_tokenId].USDT.tokenAmount - WITHDRAW_FEE)), "Withdraw USDT failed");
            investors[_tokenId].USDT.tokenAmount = 0;
        }   

        _addOwnerCommission(WITHDRAW_FEE);
        
    }

    function depositMatic() public payable {}

    function approveAllTokens() external onlyOwner {
        USDT.approve(0x1111111254EEB25477B68fb85Ed929f73A960582, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        WMATIC.approve(0x1111111254EEB25477B68fb85Ed929f73A960582, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        WBTC.approve(0x1111111254EEB25477B68fb85Ed929f73A960582, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        WETH.approve(0x1111111254EEB25477B68fb85Ed929f73A960582, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        LINK.approve(0x1111111254EEB25477B68fb85Ed929f73A960582, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    }


    function _swap(
        bytes calldata _data
    ) internal returns(uint, uint, address, address){

        (
            address executor,
            I1InchAggregatorV5.SwapDescription memory description,
            bytes memory permit,
            bytes memory data
        ) = abi.decode(
                _data[4:],
                (address, I1InchAggregatorV5.SwapDescription, bytes, bytes)
            );

        (uint returnAmount, uint spentAmount) = I1InchAggregatorV5(oneInchAggregationRouter).swap(
                executor,
                description,
                permit,
                data
            );

        return (returnAmount, spentAmount, description.srcToken, description.dstToken);
    }


    function swap(
        Pair[] memory _pairs,
        uint _amountWithoutCommission,
        uint _amountWithCommission,    
        bytes calldata _data) external onlyOwner {

        (   
            uint returnAmount,
            uint spentAmount, 
            address srcToken,
            address dstToken 
        ) = _swap(_data);

        (bool ok, uint difference) = _checkCommission(_amountWithoutCommission, _amountWithCommission);
        require(ok, "the commission goes out more than 3%");
        _addOwnerCommission(difference);
        spentAmount = _amountWithCommission; 
        
        _updateMetadata(_pairs, returnAmount, srcToken, dstToken, spentAmount);
    }
    

    function _updateMetadata(
            Pair[] memory _pairs,
            uint _returnAmount,
            address _srcToken, 
            address _dstToken,
            uint _pool) internal {
        
        uint length = _pairs.length;

        for (uint i=0; i<length; i++){

            (uint _limitInvestAmount, uint _dailySwapsAmount, uint _dayLastTx) = _getDaysMetadata(_pairs[i].tokenId, _dstToken);

            _validationDailySwaps(_pairs[i].tokenId, _pairs[i].amount, _dstToken, _dayLastTx, _dailySwapsAmount, _limitInvestAmount);

            uint partDistribution = _returnAmount * ACCURACY * _pairs[i].amountWithCommission / (_pool * ACCURACY);

            _updateTokenInfo(_pairs[i].tokenId, _srcToken, _dstToken, partDistribution, _pairs[i].amount, 0, true, SwapOptions.Investing);

            emit Swap(_pairs[i].tokenId, _srcToken, _dstToken, partDistribution, _pairs[i].amount);
        }
    }


    function _getDaysMetadata(uint _tokenId, address _coin) internal view returns(uint _limit, uint _dailySwapsAmount, uint _dayLastTx) {
        if(_coin == address(WMATIC)){
            _limit = investors[_tokenId].MATIC.limitInvestAmount;
            _dailySwapsAmount = investors[_tokenId].MATIC.dailySwapsAmount;
            _dayLastTx = investors[_tokenId].MATIC.dayLastTx;
        } else if (_coin == address(WBTC)) {
            _limit = investors[_tokenId].BTC.limitInvestAmount;
            _dailySwapsAmount = investors[_tokenId].BTC.dailySwapsAmount;
            _dayLastTx = investors[_tokenId].BTC.dayLastTx;
        } else if (_coin == address(WETH)) {
            _limit = investors[_tokenId].ETH.limitInvestAmount;
            _dailySwapsAmount = investors[_tokenId].ETH.dailySwapsAmount;
            _dayLastTx = investors[_tokenId].ETH.dayLastTx;
        } else if (_coin == address(LINK)) {
            _limit = investors[_tokenId].LINK.limitInvestAmount;
            _dailySwapsAmount = investors[_tokenId].LINK.dailySwapsAmount;
            _dayLastTx = investors[_tokenId].LINK.dayLastTx;
        }
    }



    function _getTotalInvestedAmount(uint _tokenId, address _coin) internal view returns(uint result){

        if (_coin == address(WMATIC)){
            result = investors[_tokenId].MATIC.totalInvestedAmount;
        } else if (_coin == address(WBTC)){
            result = investors[_tokenId].BTC.totalInvestedAmount;
        }else if (_coin == address(WETH)){
            result = investors[_tokenId].ETH.totalInvestedAmount;
        }else if (_coin == address(LINK)){
            result = investors[_tokenId].LINK.totalInvestedAmount;
        }
    }

    function fixTakeProfit(
        uint _tokenId,
        bytes calldata _data) external onlyOwner{
        
        uint delta;

       (
            uint returnAmount,
            uint spentAmount,
            address srcToken,
            address dstToken
        ) = _swap(_data);
    

        uint currentInvested = _getTotalInvestedAmount(_tokenId, srcToken);
    
        bool numberSign;

        if (currentInvested <= returnAmount){
            delta = returnAmount - currentInvested;
            investPool[_tokenId] += delta;
            numberSign = true;
        } else {
            delta = currentInvested - returnAmount;
            investPool[_tokenId] -= delta;
            numberSign = false;
        }

        _updateTokenInfo(_tokenId, srcToken, dstToken, returnAmount, spentAmount, delta, numberSign, SwapOptions.Fixing);

        emit TakeProfit(_tokenId, srcToken, dstToken, int(returnAmount) - int(currentInvested));
    }


    function withdrawOwnerCommission() external onlyCommissionWallet{
        require(USDT.transfer(commissionWallet, _getOwnerCommission()), "Withdraw USDT failed");
    }


    function _getOwnerCommission() internal view returns(uint){
        return ownerCommisionAmount.tokenAmount;
    }


    function _checkCommission(uint num1, uint num2) internal pure returns (bool, uint) {

        uint256 difference = num1 - num2;
        uint256 threshold = num1 * 3 / 100;
        return (difference <= threshold, difference);
    }


    function _addOwnerCommission(uint _amount) internal {
        ownerCommisionAmount.tokenAmount += _amount;
    }


    function _updateTokenInfo(uint _tokenId,
                              address _srcToken,
                              address _dstToken, 
                              uint _returnAmount, 
                              uint _spentAmount, 
                              uint _delta, 
                              bool _numberSign, 
                              SwapOptions _option) internal{
        
        if (_srcToken == address(USDT)){
            require(_spentAmount <= investors[_tokenId].USDT.tokenAmount, "USDT balance is less than the requested");
            investors[_tokenId].USDT.tokenAmount -= _spentAmount;

        } else if (_srcToken == address(WMATIC)) {
            require(_spentAmount <= investors[_tokenId].MATIC.tokenAmount, "MATIC balance is less than the requested");
            investors[_tokenId].MATIC.tokenAmount -= _spentAmount;
            if (_option == SwapOptions.Fixing){
                investors[_tokenId].MATIC.totalInvestedAmount = 0;
                investors[_tokenId].MATIC.dailySwapsAmount = 0;

                if (_numberSign){
                    investors[_tokenId].MATIC.limitInvestAmount += _calculateInvestPool(_delta);
                } else {
                    investors[_tokenId].MATIC.limitInvestAmount -= _calculateInvestPool(_delta);
                }
            }  

        } else if (_srcToken == address(WBTC)) {
            require(_spentAmount <= investors[_tokenId].BTC.tokenAmount, "BTC balance is less than the requested");
            investors[_tokenId].BTC.tokenAmount -= _spentAmount;
            if (_option == SwapOptions.Fixing){
                investors[_tokenId].BTC.totalInvestedAmount = 0;
                investors[_tokenId].BTC.dailySwapsAmount = 0;

                if (_numberSign){
                    investors[_tokenId].BTC.limitInvestAmount += _calculateInvestPool(_delta);
                } else {
                    investors[_tokenId].BTC.limitInvestAmount -= _calculateInvestPool(_delta);
                }
            }
            

        } else if (_srcToken == address(WETH)) {
            require(_spentAmount <= investors[_tokenId].ETH.tokenAmount, "ETH balance is less than the requested");
            investors[_tokenId].ETH.tokenAmount -= _spentAmount;
            if (_option == SwapOptions.Fixing){
                investors[_tokenId].ETH.totalInvestedAmount = 0;
                investors[_tokenId].ETH.dailySwapsAmount = 0;

                if (_numberSign){
                    investors[_tokenId].ETH.limitInvestAmount += _calculateInvestPool(_delta);
                } else {
                    investors[_tokenId].ETH.limitInvestAmount -= _calculateInvestPool(_delta);
                }
            }

        } else if (_srcToken == address(LINK)) {
            require(_spentAmount <= investors[_tokenId].LINK.tokenAmount, "ETH balance is less than the requested");
            investors[_tokenId].LINK.tokenAmount -= _spentAmount;
            if (_option == SwapOptions.Fixing){
                investors[_tokenId].LINK.totalInvestedAmount = 0;
                investors[_tokenId].LINK.dailySwapsAmount = 0;
                
                if (_numberSign){
                    investors[_tokenId].LINK.limitInvestAmount += _calculateInvestPool(_delta);
                } else {
                    investors[_tokenId].LINK.limitInvestAmount -= _calculateInvestPool(_delta);
                }
            }
        }



        if (_dstToken == address(USDT)){
            investors[_tokenId].USDT.tokenAmount += _returnAmount;
        } else if (_dstToken == address(WMATIC)) {
            investors[_tokenId].MATIC.tokenAmount += _returnAmount;
            if(_option == SwapOptions.Investing){
                investors[_tokenId].MATIC.totalInvestedAmount += _spentAmount;
            }

        } else if (_dstToken == address(WBTC)) {
            investors[_tokenId].BTC.tokenAmount += _returnAmount;
            if(_option == SwapOptions.Investing){
                investors[_tokenId].BTC.totalInvestedAmount += _spentAmount;
            }
        } else if (_dstToken == address(WETH)) {
            investors[_tokenId].ETH.tokenAmount += _returnAmount;
            if(_option == SwapOptions.Investing){
                investors[_tokenId].ETH.totalInvestedAmount += _spentAmount;
            }
        } else if (_dstToken == address(LINK)) {
            investors[_tokenId].LINK.tokenAmount += _returnAmount;
            if(_option == SwapOptions.Investing){
                investors[_tokenId].LINK.totalInvestedAmount += _spentAmount;
            }
        } 
    }
    
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _transfer(from, to, tokenId);
        investors[tokenId].ownerAddress = to;
        tokens[tokenId].owner = to;
    }


    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
        investors[tokenId].ownerAddress = to;
        tokens[tokenId].owner = to;
    }


    function withdrawAllMatic() external payable onlyCommissionWallet {
        uint balance = address(this).balance;
        payable(commissionWallet).transfer(balance);
    }


    function _updateInvestPool(uint _tokenId, uint _amount, bool _positive) internal {

        uint dailyInvestAmount = _calculateInvestPool(_amount);

        if (_positive){
            investors[_tokenId].MATIC.limitInvestAmount += dailyInvestAmount;
            investors[_tokenId].BTC.limitInvestAmount += dailyInvestAmount;
            investors[_tokenId].ETH.limitInvestAmount += dailyInvestAmount;
            investors[_tokenId].LINK.limitInvestAmount += dailyInvestAmount;
        } else {
            investors[_tokenId].MATIC.limitInvestAmount -= dailyInvestAmount;
            investors[_tokenId].BTC.limitInvestAmount -= dailyInvestAmount;
            investors[_tokenId].ETH.limitInvestAmount -= dailyInvestAmount;
            investors[_tokenId].LINK.limitInvestAmount -= dailyInvestAmount;
        }
    }


    function _calculateInvestPool(uint _amount) internal pure returns(uint){
        return _amount / 120;
    }

    function panicWithdraw(uint _tokenId) external {
        require(investors[_tokenId].ownerAddress == msg.sender, "You are not the owner");

        if (investors[_tokenId].USDT.tokenAmount != 0){
            require(USDT.transfer(msg.sender, investors[_tokenId].USDT.tokenAmount), "Withdraw USDT failed");
        }
        if (investors[_tokenId].MATIC.tokenAmount != 0){
            require(WMATIC.transfer(msg.sender, investors[_tokenId].MATIC.tokenAmount), "Withdraw MATIC failed");
        }
        if (investors[_tokenId].ETH.tokenAmount != 0){
            require(WETH.transfer(msg.sender, investors[_tokenId].ETH.tokenAmount), "Withdraw ETH failed");
        }
        if (investors[_tokenId].BTC.tokenAmount != 0){
            require(WBTC.transfer(msg.sender, investors[_tokenId].BTC.tokenAmount), "Withdraw BTC failed");
        }
        if (investors[_tokenId].LINK.tokenAmount != 0){
            require(LINK.transfer(msg.sender, investors[_tokenId].LINK.tokenAmount), "Withdraw LINK failed");
        }

        investPool[_tokenId] = 0;

        _resetMetadata(_tokenId);
    }

    function _resetMetadata(uint _tokenId) internal {

        investors[_tokenId].USDT.tokenAmount = 0;

        investors[_tokenId].MATIC.tokenAmount = 0;
        investors[_tokenId].MATIC.limitInvestAmount = 0;
        investors[_tokenId].MATIC.totalInvestedAmount  = 0;

        investors[_tokenId].ETH.tokenAmount = 0;
        investors[_tokenId].ETH.limitInvestAmount = 0;
        investors[_tokenId].ETH.totalInvestedAmount  = 0;

        investors[_tokenId].BTC.tokenAmount = 0;
        investors[_tokenId].BTC.limitInvestAmount = 0;
        investors[_tokenId].BTC.totalInvestedAmount  = 0;

        investors[_tokenId].LINK.tokenAmount = 0;
        investors[_tokenId].LINK.limitInvestAmount = 0;
        investors[_tokenId].LINK.totalInvestedAmount  = 0;
    }

    function _getDate() public view returns (uint256) {
        return (block.timestamp - deploymentDate) / (60 * 60 * 24);
    }


    function _checkDailySwapsLimit(uint _todayInvested, uint _amount, uint _dailyLimit) internal pure returns(bool) {
        return ((_todayInvested + _amount) <= _dailyLimit);
    }


    function _validationDailySwaps(uint _tokenId, uint _addAmount, address _addr, uint _dayLastTx, uint _dailySwapsAmount, uint _limitInvestAmount) internal {
        bool allowed = _checkDailySwapsLimit(_dailySwapsAmount, _addAmount, _limitInvestAmount);
        uint today = _getDate();
        if(_addr == address(WMATIC)){
            if (allowed && _dayLastTx == today){
                investors[_tokenId].MATIC.dailySwapsAmount += _addAmount;
                investors[_tokenId].MATIC.dayLastTx = today;

            } else if(!allowed && _dayLastTx == today){ 
                revert("Daily MATIC limit reached");

            } else {
                investors[_tokenId].MATIC.dailySwapsAmount = _addAmount;
                investors[_tokenId].MATIC.dayLastTx = today;
            }
        }

        else if(_addr == address(WBTC)){
            if (allowed && _dayLastTx == today){
                investors[_tokenId].BTC.dailySwapsAmount += _addAmount;
                investors[_tokenId].BTC.dayLastTx = today;

            } else if(!allowed && _dayLastTx == today){ 
                revert("Daily BTC limit reached");

            } else {
                investors[_tokenId].BTC.dailySwapsAmount = _addAmount;
                investors[_tokenId].BTC.dayLastTx = today;
            }
        }

        else if(_addr == address(WETH)){
            if (allowed && _dayLastTx == today){
                investors[_tokenId].ETH.dailySwapsAmount += _addAmount;
                investors[_tokenId].ETH.dayLastTx = today;

            } else if(!allowed && _dayLastTx == today){ 
                revert("Daily ETH limit reached");

            } else {
                investors[_tokenId].ETH.dailySwapsAmount = _addAmount;
                investors[_tokenId].ETH.dayLastTx = today;
            }
        }

        else if(_addr == address(LINK)){
            if (allowed && _dayLastTx == today){
                investors[_tokenId].LINK.dailySwapsAmount += _addAmount;
                investors[_tokenId].LINK.dayLastTx = today;

            } else if(!allowed && _dayLastTx == today){ 
                revert("Daily LINK limit reached");

            } else {
                investors[_tokenId].LINK.dailySwapsAmount = _addAmount;
                investors[_tokenId].LINK.dayLastTx = today;
            }
        }    
    }
}