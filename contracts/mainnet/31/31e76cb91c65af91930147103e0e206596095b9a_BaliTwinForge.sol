/**
 *Submitted for verification at polygonscan.com on 2022-10-20
*/

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

library Counters {
    struct Counter {
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

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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


interface IERC1155 is IERC165 {



    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);





    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );





    event ApprovalForAll(address indexed account, address indexed operator, bool approved);




    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);


    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);





    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);





    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


interface ERC20 is IERC20 {
	function mint (address to, uint amount) external;
	function burnFrom (address account, uint amount) external;
}

interface ERC721 is IERC721 {
	function mint (address to, uint id, bytes memory data) external;
	function burn (uint id) external;
}

interface ERC1155 is IERC1155 {
	function mint (address to, uint id, uint amount, bytes memory data) external;
	function mintBatch (address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external;

	function burn (address account, uint id, uint amount) external;
	function burnBatch (address account, uint[] memory ids, uint[] memory amounts) external;
}

/// @title Forge
/// @author BaliTwin Developers
/// @notice Forge is a contract that allows you to craft Tokens from other Tokens
/// @custom:version 1.0.0
/// @custom:website https://balitwin.com
/// @custom:security-contact [email protected]
contract BaliTwinForge is Ownable { 
	using Counters for Counters.Counter;
	
	/// @notice Token requirements for crafting
	struct IO {
		address token;
		uint[] ids;
		uint[] amounts;
	}


	struct Recipe {
		IO input;
		IO output;

		uint limit;
		uint count;

		IO fee;
	}

	/// @notice mapping of recipe id to recipe
	mapping (uint => Recipe) private _recipes;
	Counters.Counter private _recipesCounter;

	event Crafted (uint indexed id, address indexed sender);

	modifier onlyActive (uint id) {
		require(_recipes[id].input.token != address(0), 'BaliTwinForge: recipe does not exist');
		require(_recipes[id].count < _recipes[id].limit, 'BaliTwinForge: recipe limit reached');
		_;
	}

	// Actions



	function craft (uint id) payable public onlyActive(id) {
		Recipe memory _recipe = _recipes[id];

		// Payment

		if (_recipe.fee.token == address(0)) {
			if (_recipe.fee.amounts.length > 0)
				require(msg.value == _recipe.fee.amounts[0], 'BaliTwinForge: invalid fee amount');
				
		} else if (ERC721(_recipe.fee.token).supportsInterface(type(IERC721).interfaceId))
			ERC721(_recipe.fee.token).transferFrom(msg.sender, address(this), _recipe.fee.ids[0]);

		else if (ERC1155(_recipe.fee.token).supportsInterface(type(IERC1155).interfaceId))
			ERC1155(_recipe.fee.token).safeTransferFrom(msg.sender, address(this), _recipe.fee.ids[0], _recipe.fee.amounts[0], '');

		else require(
			ERC20(_recipe.fee.token).transferFrom(msg.sender, address(this), _recipe.fee.amounts[0]),
			'BaliTwinForge: transfer failed'
		);

		// Burn input
			
		if (ERC721(_recipe.input.token).supportsInterface(type(IERC721).interfaceId))
			ERC721(_recipe.input.token).burn(_recipe.input.ids[0]);
		
		else if (ERC1155(_recipe.input.token).supportsInterface(type(IERC1155).interfaceId))
				ERC1155(_recipe.input.token).burnBatch(msg.sender, _recipe.input.ids, _recipe.input.amounts);
	
		else ERC20(_recipe.input.token).burnFrom(msg.sender, _recipe.input.amounts[0]);

		// Mint output

		if (ERC721(_recipe.output.token).supportsInterface(type(IERC721).interfaceId))
			ERC721(_recipe.output.token).mint(msg.sender, _recipe.output.ids[0], '');

		else if (ERC1155(_recipe.output.token).supportsInterface(type(IERC1155).interfaceId))
			ERC1155(_recipe.output.token).mintBatch(msg.sender, _recipe.output.ids, _recipe.output.amounts, '');
		
		else ERC20(_recipe.output.token).mint(msg.sender, _recipe.output.amounts[0]);

		_recipes[id].count++;
		emit Crafted(id, msg.sender);
	}

	// View functions







	function recipe (uint id) public view returns (Recipe memory) {
		return _recipes[id];
	}





	function recipes () public view returns (uint[] memory) {
		uint[] memory active = new uint[](_recipesCounter.current());
		uint counter = 0;

		for (uint i = 0; i < _recipesCounter.current(); i++) {
			if (_recipes[i].count < _recipes[i].limit) {
				active[counter] = i;
				counter++;
			}
		}

		uint[] memory result = new uint[](counter);
		for (uint i = 0; i < counter; i++) result[i] = active[i];

		return result;
	}







	
	function recipesByInputToken (address collection, uint id) public view returns (uint[] memory) {
		uint[] memory active = new uint[](_recipesCounter.current());
		uint counter = 0;

		for (uint i = 0; i < active.length; i++) {
			if (_recipes[i].input.token != collection || _recipes[i].limit <= _recipes[i].count) continue;
			
			for (uint j = 0; j < _recipes[i].input.ids.length; j++)
				if (_recipes[i].input.ids[j] == id) {
					active[counter] = i;
					counter++;
					break;
				}
		}

		uint[] memory result = new uint[](counter);
		for (uint i = 0; i < counter; i++) result[i] = active[i];

		return result;
	}








	function recipesByOutputToken (address collection, uint id) public view returns (uint[] memory) {
		uint[] memory active = new uint[](_recipesCounter.current());
		uint counter = 0;

		for (uint i = 0; i < active.length; i++) {
			if (_recipes[i].output.token != collection || _recipes[i].limit <= _recipes[i].count) continue;
			
			for (uint j = 0; j < _recipes[i].output.ids.length; j++)
				if (_recipes[i].output.ids[j] == id) {
					active[counter] = i;
					counter++;
					break;
				}
		}

		uint[] memory result = new uint[](counter);
		for (uint i = 0; i < counter; i++) result[i] = active[i];

		return result;
	}

	// Owner functions	







	function addRecipe (IO calldata input, IO calldata output, IO calldata fee, uint limit) public onlyOwner returns (uint) {
		require(limit > 0, 'BaliTwinForge: limit must be greater than 0');
		
		require(input.token != address(0), 'BaliTwinForge: input token cannot be zero address');
		require(output.token != address(0), 'BaliTwinForge: output token cannot be zero address');

		require(fee.ids.length == fee.amounts.length, 'BaliTwinForge: fee ids and amounts length mismatch');
		require(input.ids.length == input.amounts.length, 'BaliTwinForge: input ids and amounts length mismatch');
		require(output.ids.length == output.amounts.length, 'BaliTwinForge: output ids and amounts length mismatch');
		
		uint id = _recipesCounter.current();

		_recipes[id] = Recipe(input, output, limit, 0, fee);
		_recipesCounter.increment();

		return id;
	}
	







	function setRecipeFee (uint id, IO calldata fee) public onlyOwner {
		_recipes[id].fee = fee;
	}








	function setRecipeLimit (uint id, uint limit) public onlyOwner {
		require(_recipes[id].count <= limit, 'BaliTwinForge: recipe count is higher than limit');
		_recipes[id].limit = limit;
	}








	
	function withdraw (address token, uint amount, address to) public onlyOwner {
		if (token == address(0))
			payable(to).transfer(amount);

		else ERC20(token).transfer(to, amount);
	}





	function destroy () public onlyOwner { 
		selfdestruct(payable(owner()));
	}
	
	receive () external payable {}

	fallback () external payable {}

}