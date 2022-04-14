/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

struct CustomerMeta {
    string name;
    address collectionOwner;
    address[] bindingCollections;
    bool enabled;
    uint32 lastIndex;
}
//owner account for local test net
//address constant BKOPY_PROTOCOL_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
//owner account for polygon mumbai
address constant BKOPY_PROTOCOL_OWNER =  0x59F5B98D5b5fc01c8aE10238b93618053E62BE20;


/** @title Root contract for BKEmbeded Protocol 
 *  @author BKopy.io, 2022
 */
contract BKEmbedRoot {
    /**@dev For prevening duplicate customer names */ 
    mapping(string=>address) private customerNameMap; 
    mapping (address=>CustomerMeta) private customerMetaMap;  //customer address => CustomerMeta
    mapping(address=>address) private custAddressByCollectionMap; //BindingCollectionAddress => collectionOwner;
    mapping(address => address[]) private delegates; //List of delgate address for a collection owner.  These delegates will have full control over the collection.

    address private _factoryAddress;   //These are common utility contracts for all BKCatalog implementations.
    address private _rendererAddress;
    address private _bkLibraryAddress;
    address private _bkStringsAddress;

  
    address private owner;  //BKOPY_PROTOCOL_ADDRESS

    modifier onlyOwner() {
        owner = BKOPY_PROTOCOL_OWNER;
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    
    constructor() {  
        require(msg.sender == BKOPY_PROTOCOL_OWNER, "onlyProtocolOwner") ;
        owner = msg.sender;
    }

    function BKVersion() public pure returns (string memory) {
        return "0.1.0";
    }

    function newCollection(address collectionOwner_, address bindingCollectionAddress) public onlyOwner {
        CustomerMeta storage meta = customerMetaMap[collectionOwner_];
        require(meta.enabled, "customer not registered");
        
        meta.bindingCollections.push(bindingCollectionAddress);
        meta.lastIndex = uint32(meta.bindingCollections.length);
        custAddressByCollectionMap[bindingCollectionAddress]=collectionOwner_;


    }
     

    function isCustomerRegistered(address customerAddress) public view returns(bool) {
         if (customerMetaMap[customerAddress].enabled) return true;
         return false;
    }
    function setProtocolContracts( address factory, address renderer, address bklibrary, address bkstrings)
            public onlyOwner {
        _factoryAddress = factory;
        _rendererAddress = renderer;
        _bkLibraryAddress = bklibrary;
        _bkStringsAddress = bkstrings;

    }

    /** returns BKFactoryAdresss instance */
    function factoryAddress()  public view returns(address) {
        return _factoryAddress;
    }
    /** returns BKRendererAddress for instance */
    function rendererAddress()  public view returns(address) {
        return _rendererAddress;
    }

    /** return BKLibrary adress */
    function libraryAddress() public view returns(address) {
        return _bkLibraryAddress;
    }
    function bkStringsAddress() public view returns(address) {
        return _bkStringsAddress;
    }

    function getBindingCollAddress() public view returns(address) {
        return getBindingCollAddress(msg.sender);
    }

    /**Returns the last binding collection created by owner */
    function getBindingCollAddress(address collectionOwner_) public view returns(address) {
       
        CustomerMeta  memory meta = customerMetaMap[collectionOwner_];
        address[] memory collsArray = meta.bindingCollections;
        require(collsArray.length>0, "No collections for customer");
        uint index = uint(collsArray.length) -1;
        return collsArray[index];

    }

    /**Returns the address of the indexed binding collection owned by collectionOwner. */
    function getBindingCollAddress(address collectionOwner_, uint32 index_) public view returns(address) {
        CustomerMeta  memory meta = customerMetaMap[collectionOwner_];
        address[] memory collsArray = meta.bindingCollections;
        require(collsArray.length > uint(index_), "Index out of bounds");
        return collsArray[uint(index_)];
    }
  


    function collectionOwner(address collection) private view returns(address) {
        address collOwner = custAddressByCollectionMap[collection];
        require(collOwner !=address(0), "no such collection");
        return collOwner;
    }
    
    /** A delegate is either the collection owner or a delegate created by the collection owner
        with grant delegate */
    function isDelegate(address delegate,address collection) public view returns(bool) {
        if(delegate==owner) return true;    
        if(delegate == collectionOwner(collection)) return true;       
        if(inArray(delegates[collection], delegate)) return true;
        return false;
    }

    /** Grantes a delegate who can manage the bidningCollection */
    function grantDelegate(address delegate, address collection ) public {
        require(delegate != address(0), "delegate is address(0)");
        require(msg.sender == collectionOwner(collection) || msg.sender==owner, "unauthorized");
        //don't push twice
        if (!isDelegate(delegate, collection)) {
            delegates[collection].push(delegate);
        }
    }

    /**Revokes the delegate */
    function revokeDelegate(address delegate, address collection) public {
        require(delegate != address(0), "delegate is address(0)");
        require(msg.sender == collectionOwner(collection) || msg.sender==owner, "unauthorized");
        deleteFromArray(delegates[collection], delegate);
    }

    //helpers

    //address array handling

    function inArray(address[] memory source, address needle) private pure returns(bool) {
        if (source.length==0) return false;
        for(uint i=0; i<source.length; i++) {
            if (needle==source[i]) return true;
        }
        return false;
    }
    function deleteFromArray(address[] storage source, address needle) private {
        if (!inArray(source, needle)) return; //nothing to delete
        if(source.length==1 && source[0]==needle) {
            source.pop();
            return;
        }
        for(uint i=0; i<source.length; i++) {
            if(source[i]==needle) {
                if(i<(source.length-1)) {  //check that item isn't last element
                  source[i]=source[source.length-1]; //swap deleted item with last element.
                }
                source.pop();
            }
        }
    }

    function registerCustomer(string memory name, address customerAddress) public onlyOwner {
        CustomerMeta memory meta;
        require(!(isCustomerRegistered(customerAddress)), "customer already registered.");
        meta.name = name;
        meta.collectionOwner = customerAddress;
        meta.enabled=true;
        meta.lastIndex = 0;
        customerMetaMap[customerAddress] = meta;
        customerNameMap[name]=customerAddress;
    }

    function selfDestruct() public onlyOwner {
        selfdestruct(payable(owner));
    }



}