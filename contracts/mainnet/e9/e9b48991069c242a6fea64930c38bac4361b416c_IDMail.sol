/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

/**
* Nama Aplikasi: ID-Mail
*/

contract IDMail {
    // id email
    uint256 mailId;
    // email penerima
    mapping(address => uint256[]) mailReceived;
    // email pengirim
    mapping(address => uint256[]) mailSent;

    // konten email diterima
    mapping(uint256 => string) mailContent;

    struct Profile {
        address id;
        string pubKey;
    }

    // pemetaan profil
    mapping(address => Profile) profiles;

    // event mengirim email
    event Sent(address indexed _from, address indexed _to, uint256 indexed _id, string _value);

    /**
    * @dev mengirim email ke pengguna
    */
    function send(address _to, string memory _value) public {
        mailContent[mailId] = _value;
        mailReceived[_to].push(mailId);
        mailSent[msg.sender].push(mailId);
        emit Sent(msg.sender, _to, mailId, _value);
        mailId++;
    }

    /**
    * pengaturan Public Key
        pengguna
    */
    function setKey(string memory _key) public {
        profiles[msg.sender] = Profile(msg.sender, _key);
    }

    /**
    * @dev mendapatkan profil
    *@param _address address dari query pengguna
    */
    function getKey(address _address) public view returns (string memory) {
        return profiles[_address].pubKey;
    }

    /**
    * @dev return received mails
    * @return mails ke pengguna
    */
    function getReceived() public view returns (uint256[] memory) {
        return mailReceived[msg.sender];
    }
}