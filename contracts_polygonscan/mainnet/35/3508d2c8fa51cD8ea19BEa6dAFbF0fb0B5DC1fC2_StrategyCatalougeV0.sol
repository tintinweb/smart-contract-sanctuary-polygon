/**
 *Submitted for verification at polygonscan.com on 2022-02-09
*/

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC721/[email protected]

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;
/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/utils/[email protected]


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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


// File @openzeppelin/contracts/token/ERC721/[email protected]


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}



interface ISiloFactory is IERC721Enumerable{
    function tokenMinimum(address _token) external view returns(uint _minimum);
    function balanceOf(address _owner) external view returns(uint);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function managerFactory() external view returns(address);
    function siloMap(uint _id) external view returns(address);
    function tierManager() external view returns(address);
    function ownerOf(uint _id) external view returns(address);
    function siloToId(address silo) external view returns(uint);
    function CreateSilo(address recipient) external returns(uint);
    function setActionStack(uint siloID, address[4] memory input, address[] memory _implementations, bytes[] memory _configurationData) external;
    function Withdraw(uint siloID) external;
}


// File contracts/DeFi/Vaults/StrategyCatalogu


interface IStrategyCatalouge{
    function getStrategy(string memory _strategyName) external view returns(address catalouge, uint id, address[4] memory inputs, bytes[] memory configurationData, address[] memory implementations);
    function addNewCatalouge(address _newCatalouge) external;
    function changeOwner(address _newOwner) external;
    function editStrategy(string memory _strategyName, address[4] memory inputs, bytes[] memory configurationData, address[] memory implementations) external;
    function deprecateStrategy(string memory _strategyName) external;
}

contract StrategyCatalouge is ERC721Holder{

    address public previousCatalouge;
    address public owner;
    uint public strategyCount = 1;
    ISiloFactory Factory;

    //Preset Silo Strategies
    mapping(uint => address[4]) public strategyInputs;
    mapping(uint => bytes[]) public strategyConfigurationData;
    mapping(uint => address[]) public strategyImplementations;
    mapping(uint => bool) public strategyIsDeprecated;
    mapping(string => uint) public strategyId;

    modifier onlyOwner(){
        require(msg.sender == owner, "Gravity: Caller is not the owner");
        _;
    }

    constructor(address _previousCatalouge, address _factory){
        previousCatalouge = _previousCatalouge;
        owner = msg.sender;
        Factory = ISiloFactory(_factory);
    }

    function getStrategy(string memory _strategyName) public view returns(address catalouge, uint id, address[4] memory inputs, bytes[] memory configurationData, address[] memory implementations){
        id = strategyId[_strategyName];
        if(id == 0){//strategy not found check previous catalouge
            if(previousCatalouge != address(0)){
                (catalouge, id, inputs, configurationData, implementations) = IStrategyCatalouge(previousCatalouge).getStrategy(_strategyName);
            }
        }
        else{
            require(!strategyIsDeprecated[id], "Gravity: Strategy is Deprecated");
            catalouge = address(this);
            inputs = strategyInputs[id];
            configurationData = strategyConfigurationData[id];
            implementations = strategyImplementations[id];
        }
    }

    //check for collisions
    function createStrategy(string memory _strategyName, address[4] memory inputs, bytes[] memory configurationData, address[] memory implementations) external onlyOwner{
        (,uint id,,,) = getStrategy(_strategyName);
        require(id == 0, "Gravity: Naming Collision");
        id = strategyCount;
        strategyId[_strategyName] = id;
        strategyInputs[id] = inputs;
        strategyConfigurationData[id]  = configurationData;
        strategyImplementations[id] = implementations;
        strategyCount  += 1;
    }

    function editStrategy(string memory _strategyName, address[4] memory inputs, bytes[] memory configurationData, address[] memory implementations) public onlyOwner{
        uint id = strategyId[_strategyName];
        require(id != 0, "Gravity: Strategy not found!");
        strategyInputs[id] = inputs;
        strategyConfigurationData[id]  = configurationData;
        strategyImplementations[id] = implementations;
    }

    function deprecateStrategy(string memory _strategyName) public onlyOwner{
        uint id = strategyId[_strategyName];
        require(id != 0, "Gravity: Strategy not found!");
        strategyIsDeprecated[id] = true;
    }

    //make sure it exists
    function findAndEditStrategy(string memory _strategyName, address[4] memory inputs, bytes[] memory configurationData, address[] memory implementations) external onlyOwner{
        (address catalouge,,,,) = getStrategy(_strategyName);
        if(catalouge == address(this)){//strategy is stored here
            editStrategy(_strategyName, inputs, configurationData, implementations);
        }
        else{
            IStrategyCatalouge(catalouge).editStrategy(_strategyName, inputs, configurationData, implementations);
        }
    }

    function findAndDeprecateStrategy(string memory _strategyName) external onlyOwner{
        (address catalouge,,,,) = getStrategy(_strategyName);
        if(catalouge == address(this)){//strategy is stored here
            deprecateStrategy(_strategyName);
        }
        else{
            IStrategyCatalouge(catalouge).deprecateStrategy(_strategyName);
        }
    }

    function upgradeCatalouge(address _newCatalouge) external onlyOwner{
        if(previousCatalouge != address(0)){
            IStrategyCatalouge(previousCatalouge).addNewCatalouge(_newCatalouge);
        }
        _changeOwner(_newCatalouge);
    }

    function changeOwner(address _newOwner) external onlyOwner{
        _changeOwner(_newOwner);
    }

    function _changeOwner(address _newOwner) internal{
        owner = _newOwner;
    }

}


// File contracts/DeFi/Vaults/Actions/StrategyCatalogueV
//Stores information for working with farms with editable split and transfer
contract StrategyCatalougeV0 is StrategyCatalouge{

    constructor(address _previousCatalouge, address _factory) StrategyCatalouge(_previousCatalouge, _factory){}

    //internal function to set the strategy for a silo the catalouge owns
    //for farms with editable  split and transfer
    function _setStrategy0(uint _siloId, string memory _strategyName, uint[4] memory _ratio, address[4] memory _recipients) internal{
        (,, address[4] memory inputs, bytes[] memory configurationData, address[] memory implementations) = getStrategy(_strategyName);
        (address[4] memory splitterInputs, address[4] memory splitterOutputs) = abi.decode(configurationData[configurationData.length-1], (address[4], address[4]));
        //bytes memory configData = abi.encode(splitterInputs, splitterOutputs, _ratio, _recipients);
        //configurationData[configurationData.length-1] = configData;
        //Factory.setActionStack(_siloId, inputs, implementations, configurationData);
    }

    function oneClickStrategy0(uint _siloId, string memory _strategyName, uint[4] memory _ratio, address[4] memory _recipients) external{
        uint siloId;
        if(_siloId == 0){//user wants a new silo created
            siloId = Factory.CreateSilo(address(this));
        }
        else{//user wants to change strategy on an existing silo
            siloId = _siloId;
            //transfer silo to catalouge
            Factory.transferFrom(msg.sender, address(this), siloId);
            Factory.Withdraw(siloId);//make sure current strategy is withdrawn
        }
        _setStrategy0(siloId, _strategyName, _ratio, _recipients);
        //send silo to user
        Factory.transferFrom(address(this), msg.sender, siloId);
    }
}