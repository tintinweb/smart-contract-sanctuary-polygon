/**
 *Submitted for verification at polygonscan.com on 2022-05-07
*/

pragma solidity ^0.4.18;
contract BearAccessControl {
    
    event ContractUpgrade(address newContract);

    
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    
    bool public paused = false;

    
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    
    
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    function withdrawBalance() external onlyCFO {
        cfoAddress.transfer(this.balance);
    }


    /*** Pausable functionality adapted from OpenZeppelin ***/
modifier whenNotPaused() {
        require(!paused);
        _;
    }

    
    modifier whenPaused {
        require(paused);
        _;
    }
    
    function pause() public onlyCLevel whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        
        paused = false;
    }
}

contract BearBase is BearAccessControl {
    /*** EVENTS ***/

    event Birth(address indexed owner, uint256 BearId, uint256 matronId, uint256 sireId, uint256 genes);
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /*** DATA TYPES ***/
struct Bear {
        
        
        uint256 genes;

        
        uint64 birthTime;
        uint64 cooldownEndTime;
        
        uint32 matronId;
        uint32 sireId;
        
        uint32 siringWithId;
        
        uint16 cooldownIndex;
        
        uint16 generation;
    }

    /*** CONSTANTS ***/

    uint32[14] public cooldowns = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    /*** STORAGE ***/
Bear[] bears;
mapping (uint256 => address) public BearIndexToOwner;
mapping (address => uint256) ownershipTokenCount;

    mapping (uint256 => address) public BearIndexToApproved;

    mapping (uint256 => address) public sireAllowedToAddress;

    
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        
        
        ownershipTokenCount[_to]++;
        
        BearIndexToOwner[_tokenId] = _to;
        
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            
            delete sireAllowedToAddress[_tokenId];
            
            delete BearIndexToApproved[_tokenId];
        }
        
        Transfer(_from, _to, _tokenId);
    }

    function _createBear(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {        
        require(_matronId <= 4294967295);
        require(_sireId <= 4294967295);
        require(_generation <= 65535);

        Bear memory _Bear = Bear({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndTime: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: 0,
            generation: uint16(_generation)
        });
        uint256 newBearedId = bears.push(_Bear) - 1;

        
        
        require(newBearedId <= 4294967295);

        
        Birth(
            _owner,
            newBearedId,
            uint256(_Bear.matronId),
            uint256(_Bear.sireId),
            _Bear.genes
        );

        
        
        _transfer(0, _owner, newBearedId);

        return newBearedId;
    }
}

contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

}

contract GeneScienceInterface {
    
    function isGeneScience() public pure returns (bool);

    
    function mixGenes(uint256 genes1, uint256 genes2) public returns (uint256);
}

contract BearOwnership is BearBase, ERC721 {

    
    string public name = "Bear_Breeding";
    string public symbol = "BB";
function implementsERC721() public pure returns (bool)
    {
        return true;
    }
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return BearIndexToOwner[_tokenId] == _claimant;
    }
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return BearIndexToApproved[_tokenId] == _claimant;
    }
    function _approve(uint256 _tokenId, address _approved) internal {
        BearIndexToApproved[_tokenId] = _approved;
    }
    function rescueLostBear(uint256 _BearId, address _recipient) public onlyCOO whenNotPaused {
        require(_owns(this, _BearId));
        _transfer(this, _recipient, _BearId);
    }
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }
    function transfer(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        
        require(_to != address(0));
        
        require(_owns(msg.sender, _tokenId));

        
        _transfer(msg.sender, _to, _tokenId);
    }
    function approve(
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        
        require(_owns(msg.sender, _tokenId));

        
        _approve(_tokenId, _to);

        
        Approval(msg.sender, _to, _tokenId);
    }
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        whenNotPaused
    {
        
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

        
        _transfer(_from, _to, _tokenId);
    }
    function totalSupply() public view returns (uint) {
        return bears.length - 1;
    }
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address owner)
    {
        owner = BearIndexToOwner[_tokenId];

        require(owner != address(0));
    }

    function tokensOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256 tokenId)
    {
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) {
            if (BearIndexToOwner[i] == _owner) {
                if (count == _index) {
                    return i;
                } else {
                    count++;
                }
            }
        }
        revert();
    }
}


contract BearBreeding is BearOwnership {

    event Pregnant(address owner, uint256 matronId, uint256 sireId);

    event AutoBirth(uint256 matronId, uint256 cooldownEndTime);

    uint256 public autoBirthFee = 1000000 * 1000000000; 

    GeneScienceInterface public geneScience;

    function setGeneScienceAddress(address _address) public onlyCEO {
        GeneScienceInterface candidateContract = GeneScienceInterface(_address);
 
        require(candidateContract.isGeneScience());

        geneScience = candidateContract;
    }

    function _isReadyToBreed(Bear _br) internal view returns (bool) {        return (_br.siringWithId == 0) && (_br.cooldownEndTime <= now);
    }
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = BearIndexToOwner[_matronId];
        address sireOwner = BearIndexToOwner[_sireId];
 
        return (matronOwner == sireOwner || sireAllowedToAddress[_sireId] == matronOwner);
    }

    function _triggerCooldown(Bear storage _beared) internal {
        
        _beared.cooldownEndTime = uint64(now + cooldowns[_beared.cooldownIndex]);
        if (_beared.cooldownIndex < 13) {
            _beared.cooldownIndex += 1;
        }
    }

    function approveSiring(address _addr, uint256 _sireId)
        public
        whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        sireAllowedToAddress[_sireId] = _addr;
    }

    function setAutoBirthFee(uint256 val) public onlyCOO {
        autoBirthFee = val;
    }

    function _isReadyToGiveBirth(Bear _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndTime <= now);
    }

    function isReadyToBreed(uint256 _BearId)
        public
        view
        returns (bool)
    {
        require(_BearId > 0);
        Bear storage br = bears[_BearId];
        return _isReadyToBreed(br);
    }

    function _isValidMatingPair(
        Bear storage _matron,
        uint256 _matronId,
        Bear storage _sire,
        uint256 _sireId
    )
        private
        view
        returns(bool)
    {
        
        if (_matronId == _sireId) {
            return false;
        }

        
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

        
        
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

        
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

        
        return true;
    }

    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        Bear storage matron = bears[_matronId];
        Bear storage sire = bears[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

    function canBreedWith(uint256 _matronId, uint256 _sireId)
        public
        view
        returns(bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        Bear storage matron = bears[_matronId];
        Bear storage sire = bears[_sireId];
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
            _isSiringPermitted(_sireId, _matronId);
    }

    function breedWith(uint256 _matronId, uint256 _sireId) public whenNotPaused {
        
        require(_owns(msg.sender, _matronId));
                
        
        
        require(_isSiringPermitted(_sireId, _matronId));

        
        Bear storage matron = bears[_matronId];

        
        require(_isReadyToBreed(matron));

        
        Bear storage sire = bears[_sireId];

        
        require(_isReadyToBreed(sire));

        
        require(_isValidMatingPair(
            matron,
            _matronId,
            sire,
            _sireId
        ));

        
        _breedWith(_matronId, _sireId);
    }

    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
        
        Bear storage sire = bears[_sireId];
        Bear storage matron = bears[_matronId];

        
        matron.siringWithId = uint32(_sireId);

        
        _triggerCooldown(sire);
        _triggerCooldown(matron);

        
        
        delete sireAllowedToAddress[_matronId];
        delete sireAllowedToAddress[_sireId];

        
        Pregnant(BearIndexToOwner[_matronId], _matronId, _sireId);
    }

    function breedWithAuto(uint256 _matronId, uint256 _sireId)
        public
        payable
        whenNotPaused
    {
        
        require(msg.value >= autoBirthFee);

        
        breedWith(_matronId, _sireId);

        Bear storage matron = bears[_matronId];
        AutoBirth(_matronId, matron.cooldownEndTime);
    }

    function giveBirth(uint256 _matronId)
        public
        whenNotPaused
        returns(uint256)
    {
        
        Bear storage matron = bears[_matronId];

        require(matron.birthTime != 0);

        require(_isReadyToGiveBirth(matron));

        uint256 sireId = matron.siringWithId;
        Bear storage sire = bears[sireId];

        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes);

        address owner = BearIndexToOwner[_matronId];
        uint256 bearedId = _createBear(_matronId, matron.siringWithId, parentGen + 1, childGenes, owner);

        delete matron.siringWithId;

        return bearedId;
    }
}