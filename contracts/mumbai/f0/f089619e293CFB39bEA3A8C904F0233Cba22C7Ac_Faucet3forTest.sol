// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "../libraries/LibraryStorage.sol";
import {LibraryStorage} from "../libraries/LibraryStorage.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";


contract Faucet3forTest {

    function addToken(address token, uint256 minAmount, address priceFeedAddress) external onlyOwner {
        LibraryStorage.LibStorage storage lib = LibraryStorage.libStorage();
        lib._tokens.push(LibraryStorage.Token({tokenAddress: token,priceFeedAddress:priceFeedAddress, 
        minAmount: minAmount, balance:0, status: LibraryStorage.Status.OPEN}));
        lib._tokenVsIndex[token] = lib._tokens.length-1;
    }

    function setToken(address _token, address _priceFeedAddress, uint _minAmount, bool _isActive) external onlyOwner {  
        LibraryStorage.LibStorage storage lib = LibraryStorage.libStorage();  
        LibraryStorage.Token storage token = lib._tokens[lib._tokenVsIndex[_token]];
        token.priceFeedAddress = _priceFeedAddress;
        token.minAmount = _minAmount;
        token.status =  _isActive  ? LibraryStorage.Status.OPEN  : LibraryStorage.Status.CLOSED; 
    }

    modifier onlyOwner() {
        LibDiamond._checkOwner();
        _;
    }
            
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "contracts/interfaces/AggregatorV3Interface.sol";
// import "contracts/interfaces/IUniswapV2Router01.sol";
// import "contracts/interfaces/IERC20.sol";
// import "contracts/interfaces/IERC721.sol";
import "./LibDiamond.sol";


library LibraryStorage {

    bytes32 constant LIB_STORAGE_POSITION = keccak256("diamond.standard.lib.storage");

    enum Status {x,CLOSED,OPEN}
    event Deposit( uint indexed num, address ETH,string str);
    event Claim(string success);

    struct Token {
        address tokenAddress;
        address priceFeedAddress;
        uint256 minAmount;
        uint256 balance;
        Status status;
    }


    struct LockedAsset {
        address token;
        address payable beneficiary;
        uint amount;
        uint startDate;
        uint endDate;
        uint id;
        uint claimedAmount;
        int priceInUSD;
        uint[][] option;
        bool isExchangable;
        bool isOwned;
        Status status;
    }

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct LibStorage {
        address owner;
        Token token;
        address UNISWAP_V2_ROUTER;
        address ETH;
        address WETH;
        address DAI ;
        address CoinChestAddress;
        uint StartFee;
        uint EndFee;
        uint256 minLockDate;
        uint256 _lockId;
        Status status;
        mapping(address => uint256)  _tokenVsIndex;
        mapping(address => uint256[])  _userVsLockIds;
        mapping(uint256 => LockedAsset)  _idVsLockedAsset;
        LockedAsset LockedAsset;
        Token[] _tokens;
        uint nftFeeBalance;
        mapping(uint256 => LockedAssetNft) _idVsLockedNftAsset;
        LockedAssetNft LockedAssetNft;
        uint8 _initialized; 
        bool _initializing;
        mapping(bytes32 => RoleData) _roles;
        bytes32 DEFAULT_ADMIN_ROLE;
    }

    function libStorage() internal pure returns (LibStorage storage ls) {
        bytes32 position = LIB_STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }
    
    function getToken(address _tokenAddress) internal view returns(
        address tokenAddress, 
        uint256 minAmount, 
        uint balance, 
        address priceFeedAddress, 
        Status status
    )
    {
        LibStorage storage ls = libStorage();
        uint256 index = ls._tokenVsIndex[_tokenAddress];
        Token storage token = ls._tokens[index];          
        return (token.tokenAddress, token.minAmount,token.balance,token.priceFeedAddress,token.status);
    }

    function getLockedAsset(uint256 assetId) internal view returns(
        address token,
        address beneficiary,
        uint256 amount,
        uint256 startDate,
        uint256 endDate,
        uint256 id,
        uint claimedAmount,
        int priceInUSD,
        uint[][] memory option,
        bool isExchangable,
        Status status
    )
    {
        LibStorage storage ls = libStorage();
        LockedAsset memory asset = ls._idVsLockedAsset[assetId];
        token = asset.token;
        beneficiary = asset.beneficiary;
        amount = asset.amount;
        startDate = asset.startDate;
        endDate = asset.endDate;
        id = asset.id;
        claimedAmount=asset.claimedAmount;
        priceInUSD = asset.priceInUSD;
        option  = asset.option;
        isExchangable=asset.isExchangable;
        status=asset.status;
        return(
            token,                          
            beneficiary,
            amount,
            startDate,
            endDate,
            id,
            claimedAmount,
            priceInUSD,
            option,
            isExchangable,
            status
        );
    }

    

    function _calculateFee(uint amount, bool initFee) internal view returns(uint256 calculatedAmount) {
        LibStorage storage ls = libStorage();
        if (initFee){
            uint reminder = amount * ls.StartFee / 1000;
            calculatedAmount = ls.StartFee == 0 ? amount : amount + reminder; 
        } else {
            uint reminder = amount * ls.EndFee / 1000;
            calculatedAmount = ls.EndFee == 0 ? amount : amount + reminder ;
        }
    }
    

    function getLatestPrice(address _priceFeedAddress) internal view returns (int) {    //CHANGE: internal
        AggregatorV3Interface priceFeed;
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    // modifier onlyOwner() {
    //     LibDiamond._checkOwner();
    //     _;
    // }


// NFT LOCK part


    struct LockedAssetNft {
        address contractAddress;
        address payable beneficiary;
        uint256 tokenId;
        uint256 startDate;
        uint256 endDate;
        Status status;
    }

    // function getLockedAssetNft(uint256 id) internal view returns(
    //     address contractAddress,
    //     address beneficiary,
    //     uint256 tokenId,
    //     uint256 startDate,
    //     uint256 endDate,
    //     Status status
    // )
    // {
    //     LibStorage storage ls = libStorage();
    //     LockedAssetNft storage asset = ls._idVsLockedNftAsset[id];
    //     contractAddress = asset.contractAddress;
    //     beneficiary = asset.beneficiary;
    //     tokenId=asset.tokenId;
    //     startDate = asset.startDate;
    //     endDate = asset.endDate;
    //     status=asset.status;

    //     return(
    //         contractAddress,
    //         beneficiary,
    //         tokenId,
    //         startDate,
    //         endDate,
    //         status
    //     );
    // }


    // function depositNft(
    //     address contractAddress,
    //     address payable beneficiary,
    //     address feeContractAddress,
    //     uint256 tokenId, 
    //     uint256 endDate 
    // ) 
    //     internal 
    // {

    //     LibStorage storage ls = libStorage();

    //     require(contractAddress != address(0),"Send valid contract address");
    //     require(beneficiary != address(0),"Send valid beneficiary address");
    //     require(endDate>=ls.minLockDate,"Send correct endDate");
    //     require(IERC721(contractAddress).ownerOf(tokenId) == msg.sender, "Wrong token ID");

    //     uint256 newAmount=_calculateFeeNft(endDate);

    //     if (feeContractAddress == ls.ETH){
    //         require(msg.value >= newAmount);
    //     }
    //     IERC721(contractAddress).transferFrom(msg.sender, address(this), tokenId);
    //     ls.nftFeeBalance += newAmount; 

    //     ls._idVsLockedNftAsset[ls._lockId]= LockedAssetNft({ contractAddress: contractAddress,beneficiary: beneficiary, 
    //     tokenId:tokenId,startDate: block.timestamp, endDate: endDate, status:Status.OPEN});
    //     ls._userVsLockIds[beneficiary].push(ls._lockId);
    //     ls._lockId++;

    // }

    // function _calculateFeeNft(uint256 endDate) internal view returns(uint256) { 
    //     uint256 fee;
    //     if ((endDate - block.timestamp)/31536000<=1){
    //         fee=1;
    //     } else {
    //         fee=(endDate - block.timestamp)/31556926;
    //     }
    //     return fee;
    // }


    // function claimNft(uint256 id) internal canClaimNft(id) {
    //     LibStorage storage ls = libStorage();
    //     LockedAssetNft storage asset = ls._idVsLockedNftAsset[id];
    //     IERC721(asset.contractAddress).transferFrom(address(this), asset.beneficiary, asset.tokenId);
    //     asset.status = Status.CLOSED;
    // }

    // modifier canClaimNft(uint256 id) {
    //     LibStorage storage ls = libStorage();
    //     LockedAssetNft memory asset = ls._idVsLockedNftAsset[id];
    //     require(msg.sender == LibDiamond.contractOwner() || msg.sender == asset.beneficiary , "Only owner can claimNft");  
    //     require(asset.status == Status.OPEN,"Asset is closed");
    //     require(asset.endDate <= block.timestamp);
    //     _;
    // }





    function getMessageHash(string memory _message) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(_message));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(string memory message,bytes memory signature,address signer) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address){
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r,bytes32 s,uint8 v){
        require(sig.length == 65, "invalid signature length");
        
        assembly { 
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }


    }

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function hasRole(bytes32 role, address account) public view  returns (bool) {
        LibStorage storage ls = libStorage();
        return ls._roles[role].members[account];
    }

    
    function _checkRole(bytes32 role) internal view {
        _checkRole(role, msg.sender);
    }

    
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(string(abi.encodePacked("AccessControl: account  is missing role ")));
        }
    }

    function getRoleAdmin(bytes32 role) public view  returns (bytes32) {
        LibStorage storage ls = libStorage();
        return ls._roles[role].adminRole;
    }

  
    function grantRole(bytes32 role, address account) public  onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    
    function revokeRole(bytes32 role, address account) public  onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }


    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        LibStorage storage ls = libStorage();
        ls._roles[role].adminRole = adminRole;
    }


    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            LibStorage storage ls = libStorage();
            ls._roles[role].members[account] = true;
        }
    }

 
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            LibStorage storage ls = libStorage();
            ls._roles[role].members[account] = false;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
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
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function _msgSender() internal view  returns (address) {
        return msg.sender;
    }

    function _checkOwner() internal view {
        require(contractOwner() == _msgSender(), "Ownable: caller is not the owner");
    }

    modifier onlyOwner() {
        LibDiamond._checkOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId) external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound);
  function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}