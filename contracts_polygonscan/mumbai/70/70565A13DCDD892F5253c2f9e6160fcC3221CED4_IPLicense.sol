/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: contracts/IIPLicense.sol



pragma solidity ^0.8.7;

interface IIPLicense {
    function getLicense(
        address _address, 
        string memory _creator,
        string memory _email,
        uint256 _exclusive,
        uint256 _limit
        ) external view returns (string memory);
    function getLicense(
        string memory  _address, 
        string memory _creator,
        string memory _email,
        uint256 _exclusive,
        uint256 _limit
        ) external view returns (string memory);
}

// File: contracts/IPLicense.sol


pragma solidity ^0.8.7;



contract IPLicense is IIPLicense {
    string private constant _def1 = '1. Definitions.\n\n'
    '"Content" means any art, design, drawings, texts, videos,'
    ' audios or other forms of media that may be associated with an NFT that you Own.\n\n'
    '"NFT" means any blockchain-tracked, non-fungible token, created by the smart contract: ';

    string private constant _def2 = '"Own" means, with respect to an NFT, an NFT that you have purchased'
    ' or otherwise rightfully acquired from a legitimate source, where proof of such purchase'
    ' is recorded on the relevant blockchain.\n\n'
    '"Extensions" means third party designs that: (i) are intended for use as extensions'
    ' or overlays to the Content, (ii) do not modify the underlying Content,'
    ' and (iii) can be removed at any time without affecting the underlying Content.\n\n'
    '"Purchased NFT" means an NFT that you Own.\n\n'
    '"Third Party IP" means any third party patent rights (including, without limitation,'
    ' patent applications and disclosures), copyrights, trade secrets, trademarks,'
    ' know-how or any other intellectual property rights recognized in any country'
    ' or jurisdiction in the world.\n\n';

    string private constant _own1 = '2. Ownership.\n\n'
    'You acknowledge and agree that ';

    string private constant _own2 = ' (the "Creator") owns all legal right, title and interest in'
    ' and to the Content, and all intellectual property rights therein. The rights that'
    ' you have in and to the Content are limited to those described in this License.'
    ' Creator reserves all rights in and to the Content not expressly granted to you in this'
    ' License.\n\n';

    string private constant _lic1 = '3. License.\n\n'
    'a. General Use. Subject to your continued compliance with the terms of this License,'
    ' Creator grants you a worldwide, ';
    string private constant _lic2 = ', non-transferable, royalty-free license to use, copy, and display'
    ' the Content for your Purchased NFTs, along with any Extensions that you choose to create'
    ' or use, solely for the following purposes: (i) for your own personal, non-commercial use;'
    ' (ii) as part of a marketplace that permits the purchase and sale of your NFTs, provided'
    ' that the marketplace cryptographically verifies each NFT owner''s rights to display'
    ' the Conent for their Purchased NFTs to ensure that only the actual owner can display'
    ' the Conent; or (iii) as part of a third party website or application that permits'
    ' the inclusion, involvement, or participation of your NFTs, provided that the'
    ' website/application cryptographically verifies each NFT owner''s rights to display'
    ' the Content for their Purchased NFTs to ensure that only the actual owner can display'
    ' the Content, and provided that the Content is no longer visible once the owner'
    ' of the Purchased NFT leaves the website/application.\n\n';

    string private constant _comm1 = 'b. Commercial Use. Subject to your continued compliance with'
    ' the terms of this License, Creator grants you ';
    string private constant _comm2 = ' non-transferable license to use, copy, and display'
    ' the Content for your Purchased NFTs for the purpose of commercializing your own'
    ' merchandise that includes, contains, or consists of the Content for your Purchased NFTs'
    ' ("Commercial Use")';
    string private constant _comm3 = ', provided that such Commercial Use does not result in you'
    ' earning more than ';
    string private constant _comm4 = ' For the sake of clarity, nothing in this Section 3.b'
    ' will be deemed to restrict you from (i) owning or operating a marketplace that permits'
    ' the use and sale of NFTs generally, provided that the marketplace cryptographically'
    ' verifies each NFT owner''s rights to display the Content for their Purchased NFTs'
    ' to ensure that only the actual owner can display the Content; (ii) owning or operating'
    ' a third party website or application that permits the inclusion, involvement,'
    ' or participation of NFTs generally, provided that the third party website or'
    ' application cryptographically verifies each NFT owner''s rights to display the Content'
    ' for their Purchased NFTs to ensure that only the actual owner can display the Content,'
    ' and provided that the Content is no longer visible once the owner of the Purchased NFT'
    ' leaves the website/application';
    string private constant _comm5 = '; or (iii) earning revenue from any of the foregoing,'
    ' even where such revenue is in excess of the Limit.';

    string private constant _rest1 = '4. Restrictions.\n\n'
    'You agree that you may not, nor permit any third party to do or attempt to do any of the'
    ' foregoing without Creator''s express prior written consent in each case:\n\n'
    '(i) use the Content for your Purchased NFTs in connection with images, videos, or other'
    ' forms of media that depict hatred, intolerance, violence, cruelty, or anything else that'
    ' could reasonably be found to constitute hate speech or otherwise infringe upon the rights'
    ' of others;\n\n'
    '(ii) attempt to trademark, copyright, or otherwise acquire additional intellectual property'
    ' rights in or to the Content for your Purchased NFTs;\n\n'
    '(iii) modify the Content for your Purchased NFT in any way, including, without limitation,'
    ' the shapes, designs, drawings, attributes, or color schemes (your use of Extensions will'
    ' not constitute a prohibited modification hereunder);\n\n'
    '(iv) use the Content for your Purchased NFTs to advertise, market, or sell any third party'
    ' product or service;\n\n';

    string private constant _rest2 = '(v) use the Content for your Purchased NFTs in movies,'
    ' videos, or any other forms of media, except solely for your own personal, non-commercial use';

    string private constant _rest3 = 'extent that such use is expressly permitted in Section 3(b) above;\n\n';

    string private constant _rest4 = '(vi) sell, distribute for commercial gain (including, without'
    ' limitation, giving away in the hopes of eventual commercial gain), or otherwise commercialize'
    ' merchandise that includes, contains, or consists of the Content for your Purchased NFTs';

    string private constant _rest5 = ', except as expressly permitted in Section 3(b) above;\n\n';

    string private constant _rest6 = ' or (vii) otherwise utilize the Content for your Purchased'
    ' NFTs for your or any third party''s commercial benefit.\n\n';

    string private constant _rest7 = 'To the extent that Content associated with your Purchased'
    ' NFTs contains Third Party IP (e.g., licensed intellectual property from a celebrity,'
    ' athlete, or other public figure), you understand and agree as follows:\n\n' 
    '(w) that you will not have the right to use such Third Party IP in any way except as'
    ' incorporated in the Content, and subject to the license and restrictions contained herein;\n\n'
    '(x) that, depending on the nature of the license granted from the owner of the Third Party IP,'
    ' Creator may need to pass through additional restrictions on your ability to use the Content;\n\n'
    '(y) to the extent that Creator informs you of such additional restrictions in writing (email'
    ' or NFT airdrop is permissible), you will be responsible for complying with all such'
    ' restrictions from the date that you receive the notice, and that failure to do so will be'
    ' deemed a breach of this license;\n\n';

    string private constant _rest8 = '(z) that the Commercial Use license in Section 3(b) above will not apply;\n\n';

    string private constant _rest9 = 'The restriction in Section 4 will survive the expiration or termination of this License.\n\n';

    string private constant _terms1 = '5. Terms of License.\n\n'
    'The license granted in Section 3 above applies only to the'
    ' extent that you continue to Own the applicable Purchased NFT. If at any time you sell, trade,'
    ' donate, give away, transfer, or otherwise dispose of your Purchased NFT for any reason,'
    ' the license granted in Section 3 will immediately expire with respect to those NFTs without'
    ' the requirement of notice, and you will have no further rights in or to the Content for'
    ' those NFTs.\n\n';

    string private constant _terms2 = 'If you exceed the Limit, you will be in breach of this'
    ' License, and must send an email to Creator at ';
    string private constant _terms3 = ' within fifteen (15) days, with the phrase'
    ' "NFT License - Commercial Use" in the subject line, requesting a discussion with Creator'
    ' regarding entering into a broader license agreement or obtaining an exemption'
    ' (which may be granted or withheld in Creator''s sole and absolute discretion).\n\n';

    string private constant _terms4 = 'If you exceed the scope of the license grant in Section 3.b'
    ' without entering into a broader license agreement with or obtaining an exemption from Creator,'
    ' you acknowledge and agree that:\n\n'
    '(i) you are in breach of this License;\n\n'
    '(ii) in addition to any remedies that may be available to Creator at law or in equity,'
    ' the Creator may immediately terminate this License, without the requirement of notice;\n\n'
    'and (iii) you will be responsible to reimburse Creator for any costs and expenses incurred'
    ' by Creator during the course of enforcing the terms of this License against you.';


    function getLicense(
        string memory  _address, 
        string memory _creator,
        string memory _email,
        uint256 _exclusive,
        uint256 _limit
        ) public view virtual override returns (string memory) {

        string memory _exclusivness = _exclusive == 0? "non-exclusive" : "exclusive";
        bool _iscommercial = _limit > 0;
        bool _isunlimited = _limit == 0xffffffffffffffffffffffffffffffff;
        bool _islimited = _iscommercial && !_isunlimited;

        bytes memory _part1 = abi.encodePacked(
            _def1, _address, '\n\n', _def2,
            _own1, _creator, _own2,
            _lic1, _exclusivness, _lic2
            );
        bytes memory _part2 = _limit == 0 ? abi.encodePacked('') : abi.encodePacked(
            _comm1,
            _isunlimited ? 'an unlimited' : 'a limited',
            ', worldwide, ',
            _exclusivness,
            _comm2,
            _isunlimited ? abi.encodePacked('.') : abi.encodePacked(
                _comm3,
                _limit == 100000 ? 'One Hundred Thousand Dollars ($100,000)':
                _limit == 1000000 ?  'One Million Dollars ($1,000,000)' :
                _limit == 10000000 ? 'Ten Million Dollars ($10,000,000)' :
                string(abi.encodePacked('$', Strings.toString(_limit))),
            ' in gross revenue each year (the "Limit").'
            ),
            _comm4,
            _isunlimited ? '.' : _comm5,
            '\n\n'
        );
        bytes memory _part3 = abi.encodePacked(
            _rest1, _rest2,
            _iscommercial ? ' or to the':'',
            _islimited ? ' limited': '',
            _iscommercial ? _rest3: ';\n\n',
            _rest4,
            _iscommercial ? _rest5: ';\n\n',
            _rest6, _rest7,
            _iscommercial ? _rest8 : '',
            _rest9
        );

        bytes memory _part4 = abi.encodePacked(
            _terms1,
            _islimited ? abi.encodePacked(_terms2, _email, _terms3) : abi.encodePacked(''),
            _iscommercial ? _terms4 : ''
        );


        return string(abi.encodePacked(
            _part1, _part2, _part3, _part4
        ));
    }

    function getLicense(
        address  _address, 
        string memory _creator,
        string memory _email,
        uint256 _exclusive,
        uint256 _limit
        ) public view virtual override returns (string memory) {
            return getLicense(toString(abi.encodePacked(_address)), _creator, _email, _exclusive, _limit);
        }

    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);        
    }
}