/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// File: token/IERC721TokenReceiver.sol

pragma solidity >=0.8.0 <0.9.0;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
// File: utils/ISetter.sol

pragma solidity >=0.8.0 <0.9.0;

interface ISetter {

    /// @dev Interface of function setTokenToUsable of ELFCore.
    function setTokenToUsable(uint256 tokenId, address addr) external;
}
// File: utils/IGetter.sol

pragma solidity >=0.8.0 <0.9.0;

interface IGetter {

    /// @dev Interface used by server to check who can use the _tokenId.
    function getUser(address _nftAddress,uint256 _tokenId) external view returns (address);
    
    /// @dev Interface used by server to check who can claim coin B earned by _tokenId.
    function getCoinB(address _nftAddress,uint256 _tokenId) external view returns (address);
}
// File: token/IERC20.sol

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    /// MUST trigger when tokens are transferred, including zero value transfers.
    /// A token contract which creates new tokens SHOULD trigger a Transfer event with 
    ///  the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// Returns the total token supply.
    function totalSupply() external view returns (uint256);

    /// Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
    /// The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    /// The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
    /// This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. 
    /// The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// Allows _spender to withdraw from your account multiple times, up to the _value amount. 
    /// If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
// File: token/IERC721.sol

pragma solidity >=0.8.0 <0.9.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
// File: security/AccessControl.sol

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}
// File: security/Pausable.sol

pragma solidity >=0.8.0 <0.9.0;


contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}
// File: Commission.sol

pragma solidity ^0.8.4;







/// @title Clock auction for non-fungible tokens.
contract Commission is Pausable, IGetter, IERC721TokenReceiver{

	// error message
	string constant WRONG_PARAMETER='wrong parameter';
	string constant RENTED='rented';
	string constant NOT_RENTED='not rented';
	string constant NOT_ON_SALE='given NFT is not on sale';

	/// @dev Value should be returned when we transfer NFT to a contract via safeTransferFrom.
    bytes4 constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

	struct NFT_info {
		address seller;
		address renter;
		uint256 hire_price;
		uint256 commission_rate;
		uint256 daily_profit_limit;
		uint256 duration;
		uint256 rent_startedAt;
		bool auto_stop_contract;
	}

	// Map from NFT contract address to token ID to NFT info.
	mapping (address => mapping (uint256 => NFT_info)) NFTs_info;
	
	event NFT_info_Created(
		address indexed _nftAddress,
		uint256 indexed _tokenId,
		address seller,
		uint256 hire_price,
		uint256 commission_rate,
		uint256 daily_profit_limit,
		uint256 duration,
		bool auto_stop_contract
	);

	event Hire_Cancelled(
		address indexed _nftAddress,
		uint256 indexed _tokenId
	);

	//seller hire NFT to this contract
	function hireNFT(
		address _nftAddress,
		uint256 _tokenId,
		uint256 _hire_price,
		uint256 _commission_rate,
		uint256 _daily_profit_limit,
		uint256 _duration,
		bool _auto_stop_contract
	) external
		whenNotPaused
	{ require(_commission_rate <= 10000,WRONG_PARAMETER);
		require(_daily_profit_limit <= 10000,WRONG_PARAMETER);
		require(_duration >= 10,WRONG_PARAMETER);
		require(_duration <= 600,WRONG_PARAMETER);
		IERC721 contractInstance=IERC721(_nftAddress);
		require(msg.sender==contractInstance.ownerOf(_tokenId),NO_PERMISSION);
		address _seller = msg.sender; 
		NFT_info memory _NFT_info = NFT_info(
			_seller,
			address(0),
			_hire_price,
			_commission_rate,
			_daily_profit_limit,
			_duration,
			0,
			_auto_stop_contract
		);
		NFTs_info[_nftAddress][_tokenId] = _NFT_info;
		emit NFT_info_Created(
			_nftAddress,
			_tokenId,
			_NFT_info.seller,
			_NFT_info.hire_price,
			_NFT_info.commission_rate,
			_NFT_info.daily_profit_limit,
			_NFT_info.duration,
			_NFT_info.auto_stop_contract
		);
		_transferTo(_nftAddress,_seller,_tokenId);
		ISetter sc=ISetter(_nftAddress);
		sc.setTokenToUsable(_tokenId,msg.sender);
	}

	// seller withdraw NFT from this contract
	function deleteHireNFT(address _nftAddress, uint256 _tokenId) external whenNotPaused{
		NFT_info memory info_ = NFTs_info[_nftAddress][_tokenId];
		require(msg.sender == info_.seller,NO_PERMISSION);
		require(info_.renter==address(0),RENTED);
		_cancelHire(_nftAddress, _tokenId, info_.seller);
	}

	// renter rent nft from this contract, notice that the NFT still in this contract, just register renter's addr in this NFT 
	function rent(address _nftAddress,uint256 _tokenId) external payable whenNotPaused{
		NFT_info storage info_=NFTs_info[_nftAddress][_tokenId];
		require(msg.value >= info_.hire_price,'money not enough');
		require(info_.seller!=address(0),'not listed');
		require(info_.renter==address(0),RENTED);
		info_.rent_startedAt = block.timestamp;
		info_.renter = msg.sender;
		payable(msg.sender).transfer(msg.value - info_.hire_price);
		ISetter sc=ISetter(_nftAddress);
		sc.setTokenToUsable(_tokenId,msg.sender);
	}

	// Is called when the renter's average daily_income is less than commission_rate
	function sellerStopContract(address _nftAddress,uint256 _tokenId)external onlyAdmin{
		NFT_info memory info_=NFTs_info[_nftAddress][_tokenId];
		require(info_.renter!=address(0),NOT_RENTED);
		_cancelHire(_nftAddress,_tokenId,info_.seller);
	}

	// Is called when auto_stop_contract is true, and the renter's average daily_income is less then commission_rate
	function autoStopContract(address _nftAddress,uint256 _tokenId)external onlyAdmin{
		NFT_info memory info_=NFTs_info[_nftAddress][_tokenId];
		require(info_.auto_stop_contract == true,'not auto');
		require(info_.renter!=address(0),NOT_RENTED);
		_cancelHire(_nftAddress,_tokenId,info_.seller);
	}

	function timeExceeded(address _nftAddress,uint256 _tokenId)external{
		NFT_info memory info_=NFTs_info[_nftAddress][_tokenId];
		require(block.timestamp - info_.rent_startedAt >= info_.duration,'not expired');
		require(info_.renter!=address(0),NOT_RENTED);
		_cancelHire(_nftAddress,_tokenId,info_.seller);
	}

	function gainNFTInfo(address _nftAddress,uint256 _tokenId) external view returns(address,
		address,
		uint256,
		uint256,
		uint256,
		uint256,
		uint256,
		bool)
		{
			NFT_info memory info_=NFTs_info[_nftAddress][_tokenId];
			return(info_.seller,
			info_.renter,
			info_.hire_price,
			info_.commission_rate,
			info_.daily_profit_limit,
			info_.duration,
			info_.rent_startedAt,
			info_.auto_stop_contract);
	}

	function _cancelHire(address _nftAddress, uint256 _tokenId, address _seller) internal {
		delete NFTs_info[_nftAddress][_tokenId];
		_transfer(_nftAddress, _seller, _tokenId);
		emit Hire_Cancelled(_nftAddress, _tokenId);
	}

	function _transfer(address _nftAddress, address _receiver, uint256 _tokenId) internal {
		IERC721 _nftContract = IERC721(_nftAddress);
		_nftContract.transferFrom(address(this), _receiver, _tokenId);
	}
	
	function _transferTo(address _nftAddress, address _seller, uint256 _tokenId) internal {
		IERC721 _nftContract = IERC721(_nftAddress);
		_nftContract.transferFrom(_seller, address(this), _tokenId);
	}

	/// @dev Interface used by server to check who can use the _tokenId.
	function getUser(address _nftAddress,uint256 _tokenId) public override view returns (address){
		NFT_info memory info_=NFTs_info[_nftAddress][_tokenId];
		require(info_.seller!=address(0),NOT_ON_SALE);
		if (info_.renter!=address(0)){
			if (block.timestamp - info_.rent_startedAt >= info_.duration){
				return address(0);
			}
			else{
				return info_.renter;
			}
		}
		else{
			return info_.seller;
		}
  	}

	/// @dev Interface used by server to check who can claim coin B earned by _tokenId.
	function getCoinB(address _nftAddress,uint256 _tokenId) external override view returns (address){
		NFT_info memory info_=NFTs_info[_nftAddress][_tokenId];
		require(info_.seller!=address(0),NOT_ON_SALE);
		if (info_.renter!=address(0)){
			if (block.timestamp - info_.rent_startedAt >= info_.duration){
				return address(0);
			}
			else{
				return address(this);
			}
		}
		else{
			return info_.seller;
		}
	}

	/// @dev Admin can use this function to operate balance of ERC20 of this contract.
	function opERC20(address tar,address to, uint256 amount) external onlyAdmin{
		IERC20 ERC20Contract=IERC20(tar);
		ERC20Contract.transfer(to,amount);
	}

	/// @dev Admin can use this function to operate balance of matic of this contract.
	function opMatic(address payable to,uint256 amount) external onlyAdmin{
		to.transfer(amount);
	}

	/// @dev Required for ERC721TokenReceiver compliance.
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) override pure external returns(bytes4){
        return MAGIC_ON_ERC721_RECEIVED;
    }
}