// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract auditeContract {
    address payable contractOwner = payable(0x762cd38a55D0e7A5177D2BA202c351E739608D9C);
    uint256 public listingPrice = 0.009 ether;

    struct Audite{
        string title;
        string capaian;
        uint256 fundraised;
        address creator;
        string file;
        uint256 timestamp;
        uint256 id;


        // capaian, bukti_capaian, categori_capaian

    }

    mapping(uint256 => Audite) public auditefile;
    uint256 public fileCount = 0;

    function uploadAudite(address _creator, string memory _file, string memory _capaian, string memory _title  ) public payable returns(
        string memory,
        string memory,
        string memory,
        address
    ) {
        fileCount++;
        Audite storage audit = auditefile[fileCount];

        audit.title = _title;
        audit.creator = _creator;
        audit.capaian = _capaian;
        audit.fundraised;
        audit.file = _file;
        audit.timestamp = block.timestamp;
        audit.id = fileCount;

        return(
            _title,
            _capaian,
            _file,
            _creator
        );

    }

    function getAllAudite() public view returns (Audite[] memory){
        uint256 itemCount = fileCount;
        uint256 currentIndex = 0;

        Audite[] memory items = new Audite[](itemCount);

        for(uint256 i = 0; i < itemCount; i++){
            uint256 currentId = i + 1;
            Audite storage currentItem = auditefile[currentId];
            items[currentIndex] = currentItem;

            currentIndex += 1;
        }

        return items;
    }

    function getFile(uint256 id) external view returns(
        string memory,
        string memory,
        address,
        string memory,
        uint256,
        uint256,
        uint256
    ){
        Audite memory audite = auditefile[id];

        return(
            audite.title,
            audite.capaian,
            audite.creator,
            audite.file,
            audite.fundraised,
            audite.timestamp,
            audite.id
        );
    }

    function updateListingPrice(uint256 _listingPrice, address owner) public payable {
        require(
            contractOwner ==  owner,
            "Only contract owner can update listing price"
        );

        listingPrice = _listingPrice;
    }

    function donateToFile(uint256 _id) public payable{
        uint256 amount = msg.value;

        Audite storage audit = auditefile[_id];

        (bool sent,) = payable(audit.creator).call{value: amount}("");
        if(sent){
            audit.fundraised = audit.fundraised + amount;
        }

    }

    function withdraw(address _owner) external {
        require(_owner == contractOwner, "only owner can withdraw");
        uint256 balance = address(this).balance;
        require(balance > 0, "no fund available");

        contractOwner.transfer(balance);
    }
}