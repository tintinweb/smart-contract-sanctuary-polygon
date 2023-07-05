/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

// File: smartcontracts/Libraries/GreyhoundRaceDiamondStorage.sol


pragma solidity ^0.8.19;

library GreyhoundRace {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("greyhoundrace.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }
    struct dataNFT {
        string _object;
        bytes _data;
    }

    struct FacetERC721 {
        // Token name
        string _name;
        // Token symbol
        string _symbol;
        // Mapping from token ID to owner address
        mapping(uint256 => address) _owners;
        // Mapping owner address to token count
        mapping(address => uint256) _balances;
        // Mapping from token ID to approved address
        mapping(uint256 => address) _tokenApprovals;
        // Mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) _operatorApprovals;
        // Mapping from owner to list of owned token IDs
        mapping(address => mapping(uint256 => uint256)) _ownedTokens;
        // Mapping from token ID to index of the owner tokens list
        mapping(uint256 => uint256) _ownedTokensIndex;
        // Array with all token ids, used for enumeration
        uint256[] _allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) _allTokensIndex;
        // Counter
        uint _counter;
        // Mapping to know quantity by object
        mapping(string => uint256) _counterByObject;
        // Mapping from token ID to data
        mapping(uint256 => dataNFT) _allTokensData;
    }

    struct Node {
        uint parent;
        uint left;
        uint right;
        bool red;
    }

    struct Tree {
        uint root;
        mapping(uint => Node) nodes;
    }

    struct Reward{
        address token;
        uint amount;
        uint amount_locked;
        uint timeout;
    }

    struct Record{
        uint32 centimeters;
        uint32 milliseconds;
        bool collision;
    }

    struct GreyhoundRecord{
        address user;
        uint tokenID;
        uint register_time;
        uint end_race_time;
        bytes records;//Record[] to bytes encode, decode bytes to Record[]
    }

    struct Race{
        uint weather;
        bool isFenced;
        uint centimeters;
        uint start;
        uint end;
        uint registration_price;
        uint prizepool;
        uint minSumStats;
        uint maxSumStats;
        uint max_participants;
        uint num_participants;
    }
    struct RaceFacet{
        // Red Black Tree for Race clasification
        mapping (uint => Tree) clasification;
        uint lastRace;
        mapping(uint => Race) races;
        mapping(uint => mapping(uint=>GreyhoundRecord)) race_participant;
        mapping(uint => mapping(uint => uint)) race_time_token;
        mapping(uint => mapping(uint => uint)) token_race_record;
        mapping(address => mapping(uint => bool)) user_in_race;
        mapping (uint => uint) open_races;
        mapping (uint => uint) race_open;
        uint[] name_open_races;
    }
    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface. Implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // address permited to use the contract
        mapping(address => bool) permitedAddress;
        // institutional address
        mapping(string => address) institutionalAddress;
        // coin used in all ecosystem, default USDC
        address coin;
        // address on whitelist
        mapping(address => bool) whitelist;
        // address on blacklist
        mapping(address => bool) blacklist;
        // NFTs
        FacetERC721 nftsData;
        // Rewards to claim from races
        mapping (address => Reward[]) rewards;
        // Race Data
        RaceFacet raceData;
    }
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    function setPermitedAddress(address ad, bool permited) internal {
        DiamondStorage storage ds = diamondStorage();
        whenPermited();
        ds.permitedAddress[ad]=permited;
    }
    function whenPermited() internal view {
        require(diamondStorage().permitedAddress[msg.sender],"Diamond: Address not permited");
    }
    
    function randomNum(uint _mod) internal view returns (uint _randomNum) {
        assembly{
            let ptr := mload(0x40) //free memory pointer
            mstore(ptr,add(add(add(add(add(timestamp(),gaslimit()),gasprice()),gas()),caller()),coinbase()))
            _randomNum := mod(keccak256(ptr, add(ptr, 32)) , _mod)
        }
    }
    // Internal function version of diamondCut
    enum FacetCutAction {Add, Replace, Remove}
    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
    function diamondCut(bytes memory _data,address _init,bytes memory _calldata) internal {
        FacetCut[] memory _diamondCut=abi.decode(_data,(FacetCut[]));
        uint end=_diamondCut.length;
        uint i;
        while(i<end){
            FacetCutAction action = _diamondCut[i].action;
            if (action == FacetCutAction.Add) {
                addFunctions(_diamondCut[i].facetAddress, _diamondCut[i].functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[i].facetAddress, _diamondCut[i].functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                removeFunctions(_diamondCut[i].facetAddress, _diamondCut[i].functionSelectors);
            } else {
                revert("DiamondCut: Incorrect FacetCutAction");
            }
            assembly{
                i := add(i,1)
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "DiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "DiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        uint end=_functionSelectors.length;
        uint i;
        while(i<end){
            bytes4 selector = _functionSelectors[i];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "DiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            assembly{
                i := add(i,1)
            }
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "DiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "DiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        uint end=_functionSelectors.length;
        uint i;
        while(i<end){
            bytes4 selector = _functionSelectors[i];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "DiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
            assembly{
                i := add(i,1)
            }
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "DiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "DiamondCut: Remove facet address must be address(0)");
        uint end=_functionSelectors.length;
        uint i;
        while(i<end){
            bytes4 selector = _functionSelectors[i];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
            assembly{
                i := add(i,1)
            }
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "DiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "DiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "DiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "DiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "DiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "DiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("DiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        require(isContract(_contract), _errorMessage);
    }
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
// File: smartcontracts/Core/Diamond.sol


pragma solidity ^0.8.19;


interface IFacet {
    function getSelectors() external pure returns(bytes4[] memory selectors);
    function initialize() external;
}

contract Diamond {    

    constructor(address _contractOwner) payable { 
        GreyhoundRace.DiamondStorage storage ds = GreyhoundRace.diamondStorage();
        ds.permitedAddress[_contractOwner] = true;
    }
    // Generate cut of facets this is only useful if facet has the method getSelectors() implemented
    function generateCut(address _facet,GreyhoundRace.FacetCutAction _mode) private pure returns(bytes memory bCut){
        GreyhoundRace.FacetCut[] memory cut = new GreyhoundRace.FacetCut[](1);
        cut[0]=GreyhoundRace.FacetCut({
            facetAddress: _mode==GreyhoundRace.FacetCutAction.Remove?address(0):_facet, 
            action: _mode, 
            functionSelectors: IFacet(_facet).getSelectors()
        });
        bCut=abi.encode(cut);
    }
    // Easy add facets
    function addFacets(address[] calldata _facets) external returns(bool success){
        GreyhoundRace.whenPermited();
        uint i;
        uint end=_facets.length;
        while (i<end){
            address _facet=_facets[i];
            bytes memory _cut=generateCut(_facet,GreyhoundRace.FacetCutAction.Add);
            GreyhoundRace.diamondCut(_cut,address(0),"");
            (success,)=_facet.delegatecall(abi.encodeWithSelector(IFacet.initialize.selector));
            assembly{
                i:=add(i,1)
            }
        }
    }
    // Easy update facets
    function updateFacets(address[] calldata _facets) external returns(bool success){
        GreyhoundRace.whenPermited();
        uint i;
        uint end=_facets.length;
        while (i<end){
            address _facet=_facets[i];
            bytes memory _cut=generateCut(_facet,GreyhoundRace.FacetCutAction.Replace);
            GreyhoundRace.diamondCut(_cut,address(0),"");
            (success,)=_facet.delegatecall(abi.encodeWithSelector(IFacet.initialize.selector));
            assembly{
                i:=add(i,1)
            }
        }
    }
    // Easy remove facets
    function removeFacets(address[] calldata _facets) external {
        GreyhoundRace.whenPermited();
        uint i;
        uint end=_facets.length;
        while (i<end){
            address _facet=_facets[i];
            bytes memory _cut=generateCut(_facet,GreyhoundRace.FacetCutAction.Remove);
            GreyhoundRace.diamondCut(_cut,address(0),"");
            assembly{
                i:=add(i,1)
            }
        }
    }
    // Initialize facet if need to write data on diamondStorage
    function initializeFacet(address _facet) external {
        GreyhoundRace.whenPermited();
        (bool success,)=_facet.delegatecall(abi.encodeWithSelector(IFacet.initialize.selector));
        require(success, "Can't initialize facet");
    }
    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        GreyhoundRace.DiamondStorage storage ds;
        bytes32 position = GreyhoundRace.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        require(ds.blacklist[msg.sender] == false, "Diamond: Blacklisted");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}