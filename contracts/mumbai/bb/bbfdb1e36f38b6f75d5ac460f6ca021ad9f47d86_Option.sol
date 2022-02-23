/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;
interface IERC10001 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId, uint256 amount);

    event Mint(address indexed to, address indexed optioner, uint256 indexed tokenId, uint256 amount, address escrowToken, uint256 escrowAmount, address paymentToken, uint256 paymentAmount, uint256 expiration);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); //Approval for all tokens of a particular option grouping

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); //Approve operator for a given address and all the coins it contains pertaining to this contract

    function setApprovalForAll(address operator, bool _approved) external;
}

pragma solidity ^0.8.0;

interface IERC10001Enumerable is IERC10001 {
    function generateOption(address to, uint256 amount, address escrowToken, uint256 escrowAmount, address paymentToken, uint256 paymentAmount, uint256 expiration, address optioner) external;
    function executeOption(address to, uint256 tokenId, uint256 amount) external;
    function reclaimEscrow(uint256 tokenId) external; 
}


pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


pragma solidity ^0.8.0;

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;

interface IERC10001Metadata is IERC10001 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function Approve(address to, address owner, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function amountDifferentOptionsOwned(address owner) external view returns (uint256);
    function amountOwners(uint256 tokenId) external view returns (uint256);
    function walletOfOwner(address _owner) external view returns (uint256[] memory);
    function ownersOfOption(uint256 tokenId) external view returns (address[] memory);
    function optionerAddress(uint256 tokenId) external view returns (address);
    function optionEscrow(uint256 tokenId) external view returns (address);
    function optionEscrowAmount(uint256 tokenId) external view returns (uint256);
    function optionPayment(uint256 tokenId) external view returns (address);
    function optionPaymentAmount(uint256 tokenId) external view returns (uint256);
    function expirationBlock(uint256 tokenId) external view returns (uint256);
    function amountOfOptionsTotal() external view returns (uint256);
    function amountInGroup(uint256 tokenId) external view returns (uint256);
    function amountOfOptionOwned(uint256 tokenId, address owner) external view returns (uint256);
    function amountOptionClaimed(uint256 tokenId) external view returns (uint256);
    function amountOptionUnclaimed(uint256 tokenId) external view returns (uint256);

    function _safeTransfer(address from, address to, uint256 tokenId, uint256 amount) external;

}

pragma solidity ^0.8.0;

interface IERC10001Receiver {
    function onERC10001Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

contract ERC10001 is Context, ERC165, IERC10001, IERC10001Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals; 

    // Token the option is against
    mapping(uint256 => address) private _escrowToken;

    // Amount of tokens option is for
    mapping(uint256 => uint256) private _escrowAmount;

    // Token option needs to execute
    mapping(uint256 => address) private _paymentToken;

    // Amount of token paid to execute option
    mapping(uint256 => uint256) private _paymentAmount;

    // Amount of fungible option tokens created
    mapping(uint256 => uint256) private _amount;

    // Expiration block number or time of option
    mapping(uint256 => uint256) private _expiration;

    // Original creator address of the option 
    mapping(uint256 => address) private _optioner;

    // Mapping from token to owner to amount
    mapping(uint256 => mapping(address => uint256)) private _tokenBalance;

    // Mapping from option token to amount of different owners of that token
    mapping(uint256 => address[]) private _optionOwners;

    // Mapping from owner to amount of different types of options they own
    mapping(address => uint256[]) private _optionsOwned;

    // Array with all token ids, used for enumeration
    uint256[] private _optTokens;

    // Mapping from token ID to mapping from owner address to approved address
    mapping(uint256 => mapping(address => address)) private _optTokenApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC10001).interfaceId ||
            interfaceId == type(IERC10001Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function getBlockNumber() public view virtual returns (uint256) {
        return block.number;
    }

    function amountDifferentOptionsOwned(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ERC10001: option address balance query for the zero address");
        return _optionsOwned[owner].length;
    }

    function amountOwners(uint256 tokenId) public view virtual returns (uint256) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _optionOwners[tokenId].length;
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        return _optionsOwned[_owner];
    }

    function ownersOfOption(uint256 tokenId) public view returns (address[] memory) {
        return _optionOwners[tokenId];
    }

    function optionerAddress(uint256 tokenId) public view virtual returns (address) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _optioner[tokenId];
    }

    function optionEscrow(uint256 tokenId) public view virtual returns (address) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _escrowToken[tokenId];
    }

    function optionEscrowAmount(uint256 tokenId) public view virtual returns (uint256) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _escrowAmount[tokenId];
    }

    function optionPayment(uint256 tokenId) public view virtual returns (address) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _paymentToken[tokenId];
    }

    function optionPaymentAmount(uint256 tokenId) public view virtual returns (uint256) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _paymentAmount[tokenId];
    }

    function expirationBlock(uint256 tokenId) public view virtual returns (uint256) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _expiration[tokenId];
    }

    function amountOfOptionsTotal() public view virtual returns (uint256) {
        return _optTokens.length;
    }

    function amountInGroup(uint256 tokenId) public view virtual returns (uint256) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _amount[tokenId];
    }

    function amountOfOptionOwned(uint256 tokenId, address owner) public view virtual returns (uint256) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _tokenBalance[tokenId][owner];
    }

    function amountOptionClaimed(uint256 tokenId) public view virtual returns (uint256) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return _tokenBalance[tokenId][address(0)];
    }

    function amountOptionUnclaimed(uint256 tokenId) public view virtual returns (uint256) {
        require(tokenId <= _optTokens.length, "ERC10001: query for option that doesn't exist");
        return (amountInGroup(tokenId) - _tokenBalance[tokenId][address(0)]);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC10001: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved; //change message sender to from and make this function owner only
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _optExists(uint256 tokenId) internal view virtual returns (bool) {
        return _optioner[tokenId] != address(0);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) public virtual {
        require(_msgSender() == from || _msgSender() == _optTokenApprovals[tokenId][from] || _operatorApprovals[from][_msgSender()]); 
        _Transfer(from, to, tokenId, amount);
    }

    function _Mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        address escrowToken,
        uint256 escrowAmount,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiration,
        address optioner
    ) internal virtual {
        require(amount > 0, "ERC10001: transfer of zero or negative amount of tokens");
        require(to != address(0), "ERC10001: transfer to the zero address");

            _escrowToken[tokenId] = escrowToken;
            _escrowAmount[tokenId] = escrowAmount;
            _paymentToken[tokenId] = paymentToken;
            _paymentAmount[tokenId] = paymentAmount;
            _amount[tokenId] = amount;
            _expiration[tokenId] = expiration;
            _optioner[tokenId] = optioner;

            _optionOwners[tokenId].push(to);
            _optionsOwned[to].push(tokenId);
            _tokenBalance[tokenId][to] = amount;      
            _optTokens.push(tokenId);

        emit Mint(to, optioner, tokenId, amount, escrowToken, escrowAmount, paymentToken, paymentAmount, expiration);
    }

    function _Transfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {

        require(_containsAddress(from , _optionOwners[tokenId]), "ERC10001: transfer of token that is not own"); //redundant?
        require(_tokenBalance[tokenId][from] >= amount, "ERC10001: transfer of more tokens than are owned");
        require(amount > 0, "ERC10001: transfer of zero or negative amount of tokens");
        require(to != address(0), "ERC10001: transfer to the zero address");

        // Clear approvals from the previous owner
        _Approve(address(0), from, tokenId);

        _tokenBalance[tokenId][from] -= amount;
        if (_containsAddress(to , _optionOwners[tokenId])) {
            _tokenBalance[tokenId][to] += amount;
        }
        else {
            _optionOwners[tokenId].push(to);
            _optionsOwned[to].push(tokenId);
            _tokenBalance[tokenId][to] = amount;      
        }

        if (_tokenBalance[tokenId][from] == 0) {
            //delete ownership amount from mapping
            delete _tokenBalance[tokenId][from];

            //delete previous owner address from _optionOwners[tokenId]
            uint256 lastTokenIndex = _optionOwners[tokenId].length - 1;
            address lastTokenId = _optionOwners[tokenId][lastTokenIndex];
            for (uint i=0; i < _optionOwners[tokenId].length; i++) {
                if (_optionOwners[tokenId][i] == from) {
                    _optionOwners[tokenId][i] = lastTokenId;
                    _optionOwners[tokenId].pop();
                    break;
                }
            }

            //delete tokenId from _optionsOwned[from]
            lastTokenIndex = _optionsOwned[from].length - 1;
            uint256 lastTokenAddress = _optionsOwned[from][lastTokenIndex];
            for (uint i=0; i < _optionsOwned[from].length; i++) {
                if (_optionsOwned[from][i] == tokenId) {
                    _optionsOwned[from][i] = lastTokenAddress;
                    _optionsOwned[from].pop();
                    break;
                }
            }

        }
        
        emit Transfer(from, to, tokenId, amount);
    }

    function _Burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(_containsAddress(from , _optionOwners[tokenId]), "ERC10001: transfer of token that is not own"); //redundant?
        require(_tokenBalance[tokenId][from] >= amount, "ERC10001: transfer of more tokens than are owned");
        require(amount > 0, "ERC10001: transfer of zero or negative amount of tokens");

        // Clear approvals from the previous owner
        _Approve(address(0), from, tokenId);

        _tokenBalance[tokenId][from] -= amount;
        if (_containsAddress(address(0) , _optionOwners[tokenId])) {
            _tokenBalance[tokenId][address(0)] += amount;
        }
        else {
            _tokenBalance[tokenId][address(0)] = amount;      
        }

        if (_tokenBalance[tokenId][from] == 0) {
            //delete ownership amount from mapping
            delete _tokenBalance[tokenId][from];

            //delete previous owner address from _optionOwners[tokenId]
            uint256 lastTokenIndex = _optionOwners[tokenId].length - 1;
            address lastTokenId = _optionOwners[tokenId][lastTokenIndex];
            for (uint i=0; i < _optionOwners[tokenId].length; i++) {
                if (_optionOwners[tokenId][i] == from) {
                    _optionOwners[tokenId][i] = lastTokenId;
                    _optionOwners[tokenId].pop();
                    break;
                }
            }

            //delete tokenId from _optionsOwned[from]
            lastTokenIndex = _optionsOwned[from].length - 1;
            uint256 lastTokenAddress = _optionsOwned[from][lastTokenIndex];
            for (uint i=0; i < _optionsOwned[from].length; i++) {
                if (_optionsOwned[from][i] == tokenId) {
                    _optionsOwned[from][i] = lastTokenAddress;
                    _optionsOwned[from].pop();
                    break;
                }
            }

        }
        
        emit Transfer(from, address(0), tokenId, amount);
    }

    function _Reclaim(uint256 tokenId) internal virtual {
        uint256 lastTokenIndex = 0;
        uint256 lastTokenAddress = 0;
        address from;

        for (uint h=0; h < _optionOwners[tokenId].length; h++) {
            from = _optionOwners[tokenId][h];
            _tokenBalance[tokenId][from] = 0;

            lastTokenIndex = _optionsOwned[from].length - 1;
            lastTokenAddress = _optionsOwned[from][lastTokenIndex];
            for (uint i=0; i < _optionsOwned[from].length; i++) {
                if (_optionsOwned[from][i] == tokenId) {
                    _optionsOwned[from][i] = lastTokenAddress;
                    _optionsOwned[from].pop();
                    break;
                   }
            }
        }

        _tokenBalance[tokenId][address(0)] = amountInGroup(tokenId);
        delete _optionOwners[tokenId];
    }

    function Approve(address to, address owner, uint256 tokenId) public virtual {
        require(to != owner, "ERC10001: approval to current owner");
        require(_containsAddress(owner, _optionOwners[tokenId]), "ERC10001: not an owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC10001: approve caller is not owner nor approved for all"
        );

        _Approve(to, owner, tokenId);
    }

    function _Approve(address to, address from, uint256 tokenId) internal virtual {
        _optTokenApprovals[tokenId][from] = to;
        emit Approval(from, to, tokenId);
    }

    function _containsAddress(address elementToLookFor, address[] memory list) internal virtual returns (bool) {
        bool doesListContainElement = false;
    
        for (uint i=0; i < list.length; i++) {
            if (elementToLookFor == list[i]) {
                doesListContainElement = true;
            }
        }
        return doesListContainElement;
    }

    function _containsTokenId(uint256 elementToLookFor, uint256[] memory list) internal virtual returns (bool) {
        bool doesListContainElement = false;
    
        for (uint i=0; i < list.length; i++) {
            if (elementToLookFor == list[i]) {
                doesListContainElement = true;
            }
        }
        return doesListContainElement;
    }

}

pragma solidity ^0.8.0;

abstract contract ERC10001Enumerable is ERC10001, IERC10001Enumerable {

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC10001) returns (bool) {
        return interfaceId == type(IERC10001Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

}


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity >=0.7.0 <0.9.0;

contract Option is ERC10001Enumerable {
  using Strings for uint256;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC10001(_name, _symbol) {

  }

    function generateOption(
        address to,
        uint256 amount,
        address escrowToken,
        uint256 escrowAmount,
        address paymentToken,
        uint256 paymentAmount,
        uint256 expiration,
        address optioner
    ) public virtual {
        require(amount > 0, "ERC10001: transfer of zero or negative amount of tokens.");
        require(escrowAmount > 0, "ERC10001: transfer of zero or negative amount of tokens.");
        require(paymentAmount > 0, "ERC10001: transfer of zero or negative amount of tokens.");
        require(to != address(0), "ERC10001: transfer to the zero address.");
        require(block.number < expiration, "Expiration block is before current block.");
        
        //ERC20 Token transfer
        //Approval for tokens must be given before this function can operate
        bool transferResult = IERC20(escrowToken).transferFrom(msg.sender, address(this), escrowAmount * amount);
        require(transferResult, "ERC20 Token transfer failed. Was token approved first?");

        uint256 tokenId = amountOfOptionsTotal();
        _Mint(to, tokenId, amount, escrowToken, escrowAmount, paymentToken, paymentAmount, expiration, optioner);

        
    }

    function executeOption(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public virtual {
        require(_containsAddress(msg.sender, ownersOfOption(tokenId)), "You are not the owner of any of those Options.");
        require(amount > 0, "Cannot execute 0 or negative amount fo Options.");
        require(amount <= amountOfOptionOwned(tokenId, msg.sender), "You do not have that many Options to execute.");
        require(block.number < expirationBlock(tokenId), "Option has expired.");

        //ERC20 token sold
        if (msg.sender != optionerAddress(tokenId)) {
        require(IERC20(optionPayment(tokenId)).transferFrom(msg.sender, optionerAddress(tokenId), optionPaymentAmount(tokenId) * amount), "ERC20 Token transfer to optioner failed. Was token approved first?");
        }

        //ERC20 Token purchased 
        require(IERC20(optionEscrow(tokenId)).transfer(to, optionEscrowAmount(tokenId) * amount), "ERC20 Token transfer from contract failed");

        _Burn(msg.sender, tokenId, amount);
    }


    function reclaimEscrow(
        uint256 tokenId
    ) public virtual {
        require(msg.sender == optionerAddress(tokenId), "You are not the Optioner.");
        require(block.number >= expirationBlock(tokenId), "Option has not expired yet.");
        require(amountOptionUnclaimed(tokenId) > 0, "All options have been executed or reclaimed.");

        //ERC20 Token escrow given back to optioner
        require(IERC20(optionEscrow(tokenId)).transfer(msg.sender, optionEscrowAmount(tokenId) * amountOptionUnclaimed(tokenId)), "ERC20 Token transfer from contract failed");
            
        _Reclaim(tokenId);
        

    }

}