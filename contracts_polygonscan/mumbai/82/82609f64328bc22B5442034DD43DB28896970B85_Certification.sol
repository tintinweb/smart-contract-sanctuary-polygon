/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

pragma solidity >=0.4.22 <0.9.0;

contract Certification {
    constructor() {}

    struct Certificate {
        string on;
        string by;
        string to;
        string from;
        string contentHash;
        string ipfsHash;
        uint256 expiration_date;
    }

    mapping(bytes32 => Certificate) public certificates;

    event certificateGenerated(bytes32 _certificateId);

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function generateCertificate(
        string memory _id,
        string memory _on,
        string memory _by,
        string memory _to,
        string memory _from,
        string memory _contentHash,
        string memory _ipfsHash,
        uint256 _expiration_date
    ) public {
        bytes32 byte_id = stringToBytes32(_id);
        require(
            certificates[byte_id].expiration_date == 0,
            "Certificate with given id already exists"
        );
        certificates[byte_id] = Certificate(
            _on,
            _by,
            _to,
            _from,
            _contentHash,
            _ipfsHash,
            _expiration_date
        );
        emit certificateGenerated(byte_id);
    }

    function getData(string memory _id)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256
        )
    {
        bytes32 byte_id = stringToBytes32(_id);
        Certificate memory temp = certificates[byte_id];
        require(temp.expiration_date != 0, "No data exists");
        return (
            temp.on,
            temp.by,
            temp.to,
            temp.from,
            temp.contentHash,
            temp.ipfsHash,
            temp.expiration_date
        );
    }
}