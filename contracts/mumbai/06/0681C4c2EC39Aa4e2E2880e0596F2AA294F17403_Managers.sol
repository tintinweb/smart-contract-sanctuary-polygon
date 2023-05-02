// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";



/** TEST INFO
 * Deploy edildikten sonra Main Vault contract güvenilir adreslere ekleniyor ve ownership Main Vault contract adresine devrediliyor.
OnlyOwner olan tek fonksiyon güvenilir adres ekleme fonksiyonu. 
 */

contract Managers is Ownable {
    //Structs
    struct Topic {
        address source;
        string title;
        uint256 approveCount;
    }
    struct TopicApproval {
        address source;
        bool approved;
        bytes value;
    }
    struct Source {
        address sourceAddress;
        string sourceName;
    }

    //Storage Variables
    Topic[] public activeTopics;

    address public manager1;
    address public manager2;
    address public manager3;
    address public manager4;
    address public manager5;

    mapping(string => mapping(address => TopicApproval)) public managerApprovalsForTopic;
    mapping(address => Source) public trustedSources;

    //Custom Errors
    error SameAddressForManagers();
    error NotApprovedByManager();
    error CannotSetOwnAddress();
    error UntrustedSource();
    error TopicNotFound();
    error NotAuthorized();
    error ZeroAddress();

    //Events
    event AddTrustedSource(address addr, string name);
    event ApproveTopic(address by, string source, string title, bytes encodedValues);
    event CancelTopicApproval(address by, string title);
    event ChangeManagerAddress(address manager, string managerToChange, address newAddress, bool isApproved);
    event DeleteTopic(string title);

    constructor(address _manager1, address _manager2, address _manager3, address _manager4, address _manager5) {
        if (
            _manager1 == address(0) ||
            _manager2 == address(0) ||
            _manager3 == address(0) ||
            _manager4 == address(0) ||
            _manager5 == address(0)
        ) {
            revert ZeroAddress();
        }

        manager1 = _manager1;
        if (isManager(_manager2)) {
            revert SameAddressForManagers();
        }
        manager2 = _manager2;
        if (isManager(_manager3)) {
            revert SameAddressForManagers();
        }
        manager3 = _manager3;
        if (isManager(_manager4)) {
            revert SameAddressForManagers();
        }
        manager4 = _manager4;
        if (isManager(_manager5)) {
            revert SameAddressForManagers();
        }
        manager5 = _manager5;
        _addAddressToTrustedSources(address(this), "Managers");
    }

    //Modifiers
    modifier onlyManager(address _caller) {
        if (!isManager(_caller)) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyTrustedSources(address _sender) {
        if (trustedSources[_sender].sourceAddress == address(0)) {
            revert UntrustedSource();
        }
        _;
    }

    //Write Functions
    /** TEST INFO
     NOT: Deploy edilip Main Vault contract adresi güvenilir adreslere eklendikten sonra ownership Main Vault contract adresine devredilmektedir.
	 **** 'Only Main Vault can add an address to trusted sources'
     * Owner hesabı ile çağırıldığında 'Ownable: caller is not the owner' hatası döndüğü gözlemlendi
     * 3 manager hesabı tarafından Main Vault contract üstünden başarılı bir şeklide ekleme yapılabildiği gözlemlendi.
	 
     */
    function addAddressToTrustedSources(address _address, string memory _name) external onlyOwner {
        _addAddressToTrustedSources(_address, _name);
    }

    /** TEST INFO
     * private fonksiyona göz at
     */
    function approveTopic(
        string memory _title,
        bytes memory _encodedValues
    ) public onlyManager(tx.origin) onlyTrustedSources(msg.sender) {
        _approveTopic(_title, _encodedValues);
    }

    /** TEST INFO
	**** reverts if title not exists
	* Mevcut olmayan bir başlık ile fonksiyon çağırldığında 'TopicNotFound()' hatasının döndüğü gözlemlenmiştir.
	
	**** reverts if manager didn't voted title 
	* Manager 1 tarafından rastgele adres parametre olarak gönderilerek title oluşturulmuştur.
	* Manager 2 tarafından oluşturulan başlık için fonksiyon çağırıldığında 'NotApprovedByManager()' hatasının döndüğü gözlemlenmiştir.

	**** cancels manager's vote if voted (also tests _deleteTopic private function)
	* Manager 1 ve 2 tarafından rastgele adres parametre olarak gönderilerek title oluşturulmuştur.
	* Manager 1 tarafından fonksiyon çağırıldığında onay bilgisinin false olduğu anca title'ın hala açık olduğu gözlemlenmiştir.
	* Manager 2 tarafından fonksiyon çağırıldığında onay bilgisinin false olduğu ve title'ın aktif oylamalar listesinden silindiği gözlemlenmiştir.

	**** removes from topic list if all the managers canceled their votes
	* Manager 1 ve 2 tarafından parametre olarak rastgele adres gönderilerek onaylama yapılmıştır.
	* Manager 1 tarafından fonksiyon çağırıldığında başlığın hala oylamaya açık olduğu gözlemlenmiştir.
	* Manager 2 tarafından da fonksiyon çağırıldığında başlığın aktif oylamalardan silindiği gözlemlenmiştir.
 */
    function cancelTopicApproval(string memory _title) public onlyManager(msg.sender) {
        (bool _titleExists, uint256 _topicIndex) = _indexOfTopic(_title);
        if (!_titleExists) {
            revert TopicNotFound();
        }
        if (!managerApprovalsForTopic[_title][msg.sender].approved) {
            revert NotApprovedByManager();
        }

        activeTopics[_topicIndex].approveCount--;
        if (activeTopics[_topicIndex].approveCount == 0) {
            _deleteTopic(_title);
        } else {
            managerApprovalsForTopic[_title][msg.sender].approved = false;
        }
        emit CancelTopicApproval(msg.sender, _title);
    }

    /** TEST INFO
     * Diğer testler yapılırken dolaylı olarak test edilmiş ve uygun şekilde çalıştığı gözlemlenmiştir.
     */
    function deleteTopic(string memory _title) external onlyManager(tx.origin) onlyTrustedSources(msg.sender) {
        string memory _prefix = string.concat(trustedSources[msg.sender].sourceName, ": ");
        _title = string.concat(_prefix, _title);
        _deleteTopic(_title);
    }

    /** TEST INFO 
	 **** Managers open topic to change own address
	 * Manager 1 tarafından kendisine ait adresin değiştirilmesi isteği gönderilmiş ve 'CannotSetOwnAddress()' hatasının döndüğü gözlemlenmiştir.
	 
	 **** Cannot set to another manager address
	 * Manager1 tarafından Manager3'ün adresi Manager5'e ait adres ile değiştirilmek istendiğinde 'SameAddressForManagers()' hatasının döndüğü gözlemlenmiştir.

	 ****  Can change to valid address by approvals of 3 other managers
	 * Manager1, Manager2 ve Manager3 tarafından Manager5'e ait adres rastgele başka bir adres ile değiştirilmesinin başarılı olduğu gözlemlenmiştir.
	
	*/
    function changeManager1Address(address _newAddress) external onlyManager(msg.sender) {
        if (msg.sender == manager1) {
            revert CannotSetOwnAddress();
        }
        if (isManager(_newAddress)) {
            revert SameAddressForManagers();
        }

        string memory _title = "Change Manager 1 Address";
        bytes memory _encodedValues = abi.encode(_newAddress);
        _approveTopic(_title, _encodedValues);

        bool _isApproved = isApproved(_title, _encodedValues);
        if (_isApproved) {
            manager1 = _newAddress;
            _deleteTopic(string.concat("Managers: ", _title));
        }
        emit ChangeManagerAddress(msg.sender, "Manager1", _newAddress, _isApproved);
    }

    function changeManager2Address(address _newAddress) external onlyManager(msg.sender) {
        if (msg.sender == manager2) {
            revert CannotSetOwnAddress();
        }
        if (isManager(_newAddress)) {
            revert SameAddressForManagers();
        }

        string memory _title = "Change Manager 2 Address";
        bytes memory _encodedValues = abi.encode(_newAddress);
        _approveTopic(_title, _encodedValues);

        bool _isApproved = isApproved(_title, _encodedValues);
        if (_isApproved) {
            manager2 = _newAddress;
            _deleteTopic(string.concat("Managers: ", _title));
        }
        emit ChangeManagerAddress(msg.sender, "Manager2", _newAddress, _isApproved);
    }

    function changeManager3Address(address _newAddress) external onlyManager(msg.sender) {
        if (msg.sender == manager3) {
            revert CannotSetOwnAddress();
        }
        if (isManager(_newAddress)) {
            revert SameAddressForManagers();
        }

        string memory _title = "Change Manager 3 Address";
        bytes memory _encodedValues = abi.encode(_newAddress);
        _approveTopic(_title, _encodedValues);

        bool _isApproved = isApproved(_title, _encodedValues);
        if (_isApproved) {
            manager3 = _newAddress;
            _deleteTopic(string.concat("Managers: ", _title));
        }
        emit ChangeManagerAddress(msg.sender, "Manager3", _newAddress, _isApproved);
    }

    function changeManager4Address(address _newAddress) external onlyManager(msg.sender) {
        if (msg.sender == manager4) {
            revert CannotSetOwnAddress();
        }
        if (isManager(_newAddress)) {
            revert SameAddressForManagers();
        }

        string memory _title = "Change Manager 4 Address";
        bytes memory _encodedValues = abi.encode(_newAddress);
        _approveTopic(_title, _encodedValues);

        bool _isApproved = isApproved(_title, _encodedValues);
        if (_isApproved) {
            manager4 = _newAddress;
            _deleteTopic(string.concat("Managers: ", _title));
        }
        emit ChangeManagerAddress(msg.sender, "Manager4", _newAddress, _isApproved);
    }

    function changeManager5Address(address _newAddress) external onlyManager(msg.sender) {
        if (msg.sender == manager5) {
            revert CannotSetOwnAddress();
        }
        if (isManager(_newAddress)) {
            revert SameAddressForManagers();
        }

        string memory _title = "Change Manager 5 Address";
        bytes memory _encodedValues = abi.encode(_newAddress);
        _approveTopic(_title, _encodedValues);

        bool _isApproved = isApproved(_title, _encodedValues);
        if (_isApproved) {
            manager5 = _newAddress;
            _deleteTopic(string.concat("Managers: ", _title));
        }
        emit ChangeManagerAddress(msg.sender, "Manager5", _newAddress, _isApproved);
    }

    /**TEST INFO
     * Dolaylı olarak test edildi
     */
    function _deleteTopic(string memory _title) private {
        (bool _titleExists, uint256 _topicIndex) = _indexOfTopic(_title);
        if (!_titleExists) {
            revert TopicNotFound();
        }
        delete managerApprovalsForTopic[_title][manager1];
        delete managerApprovalsForTopic[_title][manager2];
        delete managerApprovalsForTopic[_title][manager3];
        delete managerApprovalsForTopic[_title][manager4];
        delete managerApprovalsForTopic[_title][manager5];

        if (_topicIndex < activeTopics.length - 1) {
            activeTopics[_topicIndex] = activeTopics[activeTopics.length - 1];
        }
        activeTopics.pop();
        emit DeleteTopic(_title);
    }

    /** TEST INFO
 
 ****  Untrusted sources cannot approve a topic and tx.origin must be a manager
 * Contract owner tarafından çağırıldığında 'NotAuthorized()' hatası döndüğü gözlemlenmiştir.
 * Manager adresi tarafından doğrudan çağırıldığında 'UntrustedSource()' hatası döndüğü gözlemlenmiştir.
 * Main Vault contract üzerinden Main Vault contract owner adresi ile çağırldığında ''ONLY MANAGERS: Not authorized' hatası döndüğü gözlemlenmiştir.
 
 **** Test approve topic by one manager
 * Bir manager ile parametre olarak rastgele bir cüzdan adresi gönderilerek test edilmiştir.
 * Contract üzerine 'Test Approve Topic Function' şeklinde bir title oluştuğu ve test eden manager için onay bilgisinin kaydedildiği gözlemlenmiştir.
 * Onay bilgisi içerisinde parametre olarak gönderilen rastgele cüzdan adresinin yer aldığı gözlemlenmiştir.
 * Oluşan title için onay sayısının '1' olduğu gözlemlenmiştir.
 * Başka bir title olmadığı gözlemlenmiştir.
 
 **** Test approve topic by 3 of managers 
 * Manager 1 ve 2 ile aynı rastgele adres parametre olarak gönderilerek fonksiyon çağırılmış ve oluşan title için onay sayısının 2 olduğu gözlemlenmiştir.
 * Manager 3 tarafından farklı bir rastgele adres parametre olarak gönderilmiş ve aynı title'ın onay sayısının 3'e yükseldiği ancak oylamanın devam ettiği gözlemlenmiştir.
 * Manager 4 tarafından ilk iki manager ile aynı adres parametre olarak gönderilmiş ve Main Vault contract üzerinde test değişkenine gönderilen parametredeki adresin atandığı gözlemlenmiştir.
 * Onaylanan title'ın aktif oylamalar listesinden silindiği gözlemlenmiştir.
 ****  
 */
    function _approveTopic(string memory _title, bytes memory _encodedValues) private {
        string memory _prefix = "";
        address _source;
        if (bytes(trustedSources[msg.sender].sourceName).length > 0) {
            _prefix = string.concat(trustedSources[msg.sender].sourceName, ": ");
            _source = trustedSources[msg.sender].sourceAddress;
        } else {
            if (isManager(msg.sender)) {
                _prefix = "Managers: ";
                _source = address(this);
            } else {
                revert("MANAGERS: Untrusted source");
            }
        }

        _title = string.concat(_prefix, _title);

        require(!managerApprovalsForTopic[_title][tx.origin].approved, "Already voted");

        managerApprovalsForTopic[_title][tx.origin].approved = true;
        managerApprovalsForTopic[_title][tx.origin].value = _encodedValues;
        managerApprovalsForTopic[_title][tx.origin].source = _source;

        (bool _titleExists, uint256 _topicIndex) = _indexOfTopic(_title);

        if (!_titleExists) {
            activeTopics.push(Topic({source: _source, title: _title, approveCount: 1}));
        } else {
            activeTopics[_topicIndex].approveCount++;
        }
        emit ApproveTopic(tx.origin, trustedSources[msg.sender].sourceName, _title, _encodedValues);
    }

    /** TEST INFO
     * Dolaylı olarak test edildi
     */
    function _addAddressToTrustedSources(address _address, string memory _name) private {
        if (_address == address(0)) {
            revert ZeroAddress();
        }

        trustedSources[_address].sourceAddress = _address;
        trustedSources[_address].sourceName = _name;
        emit AddTrustedSource(_address, _name);
    }

    //Read Functions

    /** TEST INFO
     **** Returns true only for manager addresses
     * Rastgele bir cüzdan adresi için sorgulandığında 'false' döndüğü gözlemlenmiştir.
     * 5 manager adresinin hepsi için ayrı ayrı sorgulandığında 'true' döndüğü gözlemlenmiştir.
     */
    function isManager(address _address) public view returns (bool) {
        return (_address == manager1 ||
            _address == manager2 ||
            _address == manager3 ||
            _address == manager4 ||
            _address == manager5);
    }

    function getActiveTopics() public view returns (Topic[] memory) {
        return activeTopics;
    }

    function isApproved(string memory _title, bytes memory _value) public view returns (bool _isApproved) {
        string memory _prefix = "";
        if (bytes(trustedSources[msg.sender].sourceName).length > 0) {
            _prefix = string.concat(trustedSources[msg.sender].sourceName, ": ");
        } else {
            if (isManager(msg.sender)) {
                _prefix = "Managers: ";
            } else {
                revert UntrustedSource();
            }
        }
        _title = string.concat(_prefix, _title);
        bytes memory _manager1Approval = managerApprovalsForTopic[_title][manager1].value;
        bytes memory _manager2Approval = managerApprovalsForTopic[_title][manager2].value;
        bytes memory _manager3Approval = managerApprovalsForTopic[_title][manager3].value;
        bytes memory _manager4Approval = managerApprovalsForTopic[_title][manager4].value;
        bytes memory _manager5Approval = managerApprovalsForTopic[_title][manager5].value;

        uint256 _totalValidVotes = 0;

        _totalValidVotes += managerApprovalsForTopic[_title][manager1].approved &&
            keccak256(_manager1Approval) == keccak256(_value)
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager2].approved &&
            keccak256(_manager2Approval) == keccak256(_value)
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager3].approved &&
            keccak256(_manager3Approval) == keccak256(_value)
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager4].approved &&
            keccak256(_manager4Approval) == keccak256(_value)
            ? 1
            : 0;
        _totalValidVotes += managerApprovalsForTopic[_title][manager5].approved &&
            keccak256(_manager5Approval) == keccak256(_value)
            ? 1
            : 0;
        _isApproved = _totalValidVotes >= 3;
    }

    function getManagerApprovalsForTitle(
        string calldata _title
    ) public view returns (TopicApproval[] memory _returnData) {
        _returnData = new TopicApproval[](5);
        _returnData[0] = managerApprovalsForTopic[_title][manager1];
        _returnData[1] = managerApprovalsForTopic[_title][manager2];
        _returnData[2] = managerApprovalsForTopic[_title][manager3];
        _returnData[3] = managerApprovalsForTopic[_title][manager4];
        _returnData[4] = managerApprovalsForTopic[_title][manager5];
    }

    function _compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _indexOfTopic(string memory _element) private view returns (bool found, uint256 i) {
        for (i = 0; i < activeTopics.length; i++) {
            if (_compareStrings(activeTopics[i].title, _element)) {
                return (true, i);
            }
        }
        return (false, 0); //Cannot return -1 with type uint256. For that check the first parameter is true or false always.
    }
}