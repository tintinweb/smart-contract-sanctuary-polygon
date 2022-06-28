// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../0_diamond/libraries/LibDiamond.sol";
import "../2_donation/DonationInternal.sol";
import "./ChatRoomInternal.sol";

contract ChatRoom is DonationInternal, ChatRoomInternal{

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function registered(string memory username_) public view returns(bool) {
        return _registered(username_);
    }

    function register(string memory username_) public {
        _register(msg.sender, username_);
    }    
    
    function unRegister() public {
        _unRegister(msg.sender);
    }

    function username(address userAddr) public view returns(string memory usename_) {
        usename_ = _username(userAddr);
        require(bytes(usename_).length > 0, "ChatRoom: query for not registered user");
    }

    function comment(string memory text, uint256 typeInt) public payable {
        _comment({
            userAddr : msg.sender, 
            userPower : _userPower(msg.sender), 
            paidAmount : msg.value, 
            text : text, 
            typeInt : typeInt
        });
    }

    function setGuestCommentFee(uint256 commentFee) public onlyOwner {
        _setGuestCommentFee(commentFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

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
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
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

    // Internal function version of diamondCut
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
        // add new facet address if it does not exist
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
        // add new facet address if it does not exist
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
        // if function does not exist then do nothing and return
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
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./DonationStorage.sol";

abstract contract DonationInternal {
    using DonationStorage for DonationStorage.Layout;
    using DonationStorage for DonationStorage.Donate;

    function _nextTokenId() internal returns(uint256) {
        return DonationStorage.layout().nextTokenId++;
    }

    function _cardPower(uint256 tokenId) internal view returns(uint256) {
        return DonationStorage.layout().donates[tokenId].votingPower;
    }

    function _userPower(address userAddr) internal view returns(uint256) {
        return DonationStorage.layout().userPower[userAddr];
    }

    function _increaseUserPower(address userAddr, uint256 amount) internal {
        DonationStorage.layout().userPower[userAddr] += amount;
    }

    function _decreaseUserPower(address userAddr, uint256 amount) internal {
        DonationStorage.layout().userPower[userAddr] -= amount;
    }

    function _newDonation(
        address userAddr,
        uint256 id,
        string memory tag,
        uint256 amount_Matic,
        uint256 amount_USD,
        uint256 blockNumber
    ) internal {
        DonationStorage.Layout storage l = DonationStorage.layout();
        require(
            amount_Matic >= l.minDonation,
            "DonationInternal: minimum donation error."
        );

        uint256 power = _consumePower(amount_Matic);

        l.donates[id] = DonationStorage.Donate(
            tag, 
            amount_Matic, 
            amount_USD, 
            power,
            blockNumber
        );
        l.userPower[userAddr] += power;
        l.totalDonation += amount_Matic;
    }

    function _consumePower(uint256 paidAmount) internal returns(uint256 powerAmount) {
        powerAmount = paidAmount / (10 ** 8) * DonationStorage.layout().powerNumenator;
        DonationStorage.layout().powerNumenator -= DonationStorage.layout().powerNumenator / 300;
    }

    function _setPowerNumenator(uint256 powerNumenator) internal {
        DonationStorage.layout().powerNumenator = powerNumenator;
    }

    function _setMinDonation(uint256 minDonation) internal {
        DonationStorage.layout().minDonation = minDonation;
    }

    function _newNotification(string memory notification) internal {
        DonationStorage.layout().notification = notification;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ChatRoomStorage.sol";
import "./utils/StringUtil.sol";
import "./utils/LiteralRegex.sol";

contract ChatRoomInternal {
    using ChatRoomStorage for ChatRoomStorage.Layout;
    using StringUtil for string;
    using LiteralRegex for string;

    event Comment(
        string username_, 
        address indexed userAddr, 
        uint256 userPower, 
        uint256 paidAmount, 
        string text, 
        uint256 indexed typeInt, 
        uint256 commentIndex_
    );
    event Register(address userAddr, string username);
    event UnRegister(address _userAddr);

    function _registered(string memory username_) internal view returns(bool) {
        return ChatRoomStorage.layout().registered[username_.lower()] != address(0);
    }

    function _register(address userAddr, string memory username_) internal {
        ChatRoomStorage.Layout storage l = ChatRoomStorage.layout();

        require(
            username_.isLiteral(),
            "you can just use numbers(0-9) letters(a-zA-Z) and signs(-._)"
        );

        string memory lower = username_.lower();

        require(
            l.registered[lower] == address(0), 
            "ChatRoomInternal: the username has already been registered"
        );

        l.users[userAddr] = username_;
        l.registered[lower] = userAddr;

        emit Register(userAddr, username_);
    }

    /**
     * @notice delete your username.
     */
    function _unRegister(address userAddr) internal {
        ChatRoomStorage.Layout storage l = ChatRoomStorage.layout();
        delete l.registered[l.users[userAddr].lower()];
        delete l.users[userAddr];
        emit UnRegister(userAddr);
    }

    /**
     * @notice returns the username of the specified address.
     */
    function _username(address userAddr) internal view returns(string memory) {
        return ChatRoomStorage.layout().users[userAddr];
    }

    function _comment(
        address userAddr,
        uint256 userPower,
        uint256 paidAmount,
        string memory text,
        uint256 typeInt
    ) internal {

        if(userPower == 0){
            require(
                paidAmount > ChatRoomStorage.layout().guestCommentFee,
                "Collection: insufficient fee for guest."
            );
        }

        emit Comment(
            _username(userAddr),
            userAddr, 
            userPower, 
            paidAmount, 
            text, 
            typeInt, 
            ChatRoomStorage.layout().commentIndex++
        );
    }

    function _setGuestCommentFee(uint256 commentFee) internal {
        ChatRoomStorage.layout().guestCommentFee = commentFee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


library DonationStorage {

    bytes32 constant DONATION_STORAGE_POSITION = keccak256("DONATION_STORAGE_POSITION");

    struct Layout {
        uint256 nextTokenId;
        uint256 minDonation;
        uint256 powerNumenator; //denumerator is 10,000
        mapping(uint256 => Donate) donates;
        mapping(address => uint256) userPower;
        string notification;
        uint256 totalDonation;
    }

    struct Donate {
        string tag;
        uint256 amount_MATIC;
        uint256 amount_USD;
        uint256 votingPower;
        uint256 blockNumber;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = DONATION_STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


library ChatRoomStorage {

    bytes32 constant CHATROOM_STORAGE_POSITION = keccak256("CHATROOM_STORAGE_POSITION");

    struct Layout {
        mapping(address => string) users;
        mapping(string => address) registered;
        uint256 commentIndex;
        uint256 guestCommentFee;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = CHATROOM_STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library StringUtil {

    /**
     * StringToUint256Hash
     * 
     * Converts a string to its corresponding uint256 hash.
     * not case sensetive.
     *
     * @return uint256 
     */
    function uint256Hash(string memory input)
        internal
        pure
        returns(uint256)
    {
        return uint256(keccak256(abi.encodePacked(lower(input))));
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) 
    {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) 
    {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library LiteralRegex {

    string constant regex = "[a-zA-Z0-9-._]";

    function isLiteral(string memory text) internal pure returns(bool) {
        bytes memory t = bytes(text);
        for (uint i = 0; i < t.length; i++) {
            if(!_isLiteral(t[i])) {return false;}
        }
        return true;
    }

    function _isLiteral(bytes1 char) private pure returns(bool status) {
        if (  
            char >= 0x30 && char <= 0x39 // `0-9`
            ||
            char >= 0x41 && char <= 0x5a // `A-Z`
            ||
            char >= 0x61 && char <= 0x7a // `a-z`
            ||
            char == 0x2d                 // `-`
            ||
            char == 0x2e                 // `.`
            ||
            char == 0x5f                 // `_`
        ) {
            status = true;
        }
    }
}