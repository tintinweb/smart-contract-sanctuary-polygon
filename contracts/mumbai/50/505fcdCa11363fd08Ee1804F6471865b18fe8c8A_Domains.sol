// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import { StringUtils } from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";

//0x505fcdCa11363fd08Ee1804F6471865b18fe8c8A

contract Domains is ERC721URIStorage {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

     // We'll be storing our NFT images on chain as SVGs
     string svgPartOne = '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="550" height="521.795" xml:space="preserve" viewBox="0 0 550 521.795"><path fill="url(#B)" d="M0 0h190.385v190.385H0z"/><g/><g/><path style="fill:#000" d="M291.099 62.13c-3.672.888-3.672.888 1.916 3.614 4.74 2.312 7.623 2.726 19.01 2.726 7.643 0 16.037.725 19.5 1.686 7.484 2.077 31.478 11.06 37.233 13.94 8.84 4.425 18.415 12.675 27.729 23.891 8.638 10.401 10.132 11.667 14.264 12.091 3.534.362 4.465.077 3.972-1.206-1.309-3.411-13.429-20.113-15.861-21.856-16.475-11.818-41.546-24.66-60.604-31.044-10.026-3.359-13.482-3.899-27.479-4.285-8.803-.242-17.66-.043-19.68.445"/><path style="fill:#000" d="M273.354 68.428c0 2.276 13.461 11.321 22.067 14.821 9.364 3.811 31.39 19.928 37.709 27.597 4.635 5.621 16.933 30.583 18.488 37.523.658 2.931 1.572 14.978 2.032 26.772.837 21.442.837 21.442-1.997 22.182-1.604.42-8.347-.808-15.535-2.825-6.987-1.963-16.119-4.149-20.294-4.861-4.175-.713-8.831-1.569-10.344-1.903-4.221-.931-3.453 2.686 1.065 5.022 5.004 2.587 48.921 21.339 49.98 21.339.448 0 .581-3.247.292-7.214-.59-8.15-1.344-7.6 12.867-9.35l6.382-.786.348-11.823.348-11.822 3.672 7.034c2.019 3.868 4.145 7.035 4.726 7.037.581.001 6.201-1.925 12.49-4.281 12.077-4.523 18.491-5.144 32.347-3.124 3.702.539 6.878.857 7.059.704.623-.527-6.726-17.6-9.933-23.069-5.267-8.986-29.3-38.758-38.313-47.459-7.198-6.95-10.791-9.216-25.511-16.086-21.14-9.869-27.942-11.927-39.447-11.927-8.036 0-11.153-.801-28.571-7.341-20.428-7.671-21.929-8.093-21.929-6.158"/><path style="fill:#000" d="M223.791 82.027c-22.493 1.978-42.734 17.635-65.027 50.299-9.658 14.149-14.583 25.099-18.794 41.764-6.744 26.704-7.76 35.621-7.501 65.835.203 23.709-.111 29.219-2.194 38.549-3.508 15.712-7.041 26.504-12.356 37.729-6.204 13.105-13.313 30.78-29.565 73.504a25197.885 25197.885 0 0 1-17.659 46.319c-2.289 5.958-4.161 11.327-4.161 11.932 0 2.86 5.208.426 14.106-6.598 12.361-9.753 16.501-12.546 39.741-26.799 20.623-12.65 26.16-14.946 40.987-16.989 11.272-1.552 15.786-3.792 18.217-9.034.949-2.049 2.578-11.16 3.617-20.246 1.29-11.286 3.606-22.533 7.308-35.489 2.981-10.433 6.325-24.308 7.432-30.834 2.15-12.672 2.892-14.703 13.34-36.518 10.101-21.095 24.264-37.871 38.613-45.736 4.73-2.594 10.305-6.474 12.388-8.624l3.788-3.907-4.988-11.984c-2.743-6.592-4.736-12.236-4.426-12.544.309-.309 4.077-1.163 8.377-1.901 7.983-1.368 22.343-.039 48.09 4.452 15.316 2.671 34.812 4.886 35.646 4.052.417-.419-.148-6.107-1.252-12.644-2.295-13.586-14.337-45.724-21.263-56.751-9.42-15-13.915-19.76-22.133-23.447-4.296-1.928-9.36-4.808-11.254-6.4-4.288-3.608-12.815-7.79-17.999-8.825-6.721-1.344-6.204 2.087 1.405 9.282 3.813 3.608 10.463 12.313 15.296 20.028 4.701 7.505 13.02 19.154 18.483 25.885 10.975 13.52 13.229 17.321 19.055 32.124 5.667 14.4 2.972 13.435-9.385-3.361-4.209-5.72-15.675-18.659-25.482-28.759-15.236-15.688-18.722-20.025-23.949-29.796-3.365-6.289-7.917-13.544-10.113-16.122-6.28-7.373-17.907-10.071-36.392-8.446M412.86 190.149c0 7.88 12.247 19.095 15.356 14.064.447-.725-.346-2.399-1.764-3.72-2.982-2.78-3.333-4.753-.84-4.753 3.653 0 6.015 1.784 9.382 7.092 2.044 3.225 5.778 6.815 9.03 8.686 6.858 3.946 22.042 20.857 25.389 28.278 5.203 11.533 20.7 59.698 25.9 80.489 2.983 11.932 7.65 32.469 10.373 45.64 4.708 22.786 9.257 41.217 10.479 42.439 1.538 1.539 2.011-9.189.825-18.814-3.701-30.094-26.721-112.037-42.93-152.812-4.957-12.474-15.16-32.38-18.347-35.8-5.406-5.805-18.725-12.425-27.562-13.701-14.523-2.099-15.289-1.954-15.289 2.914m-20.803 3.489c-6.234 2.519-6.757 3.041-7.097 7.095-.328 3.9 3.926 18.257 5.409 18.257.322 0 2.278-.876 4.347-1.944 3.565-1.845 3.724-2.233 3.012-7.426-.513-3.744-.173-6.6 1.071-9.009 1.912-3.696 2.479-9.793.905-9.73-.504.02-3.948 1.261-7.649 2.757"/><path style="fill:#000" d="M285.762 210.376c-10.505 3.003-36.393 16.264-44.116 22.598-6.79 5.571-19.645 20.084-19.674 22.212-.04 3.15 14.736 12.392 17.29 10.815.491-.305 3.4-4.323 6.461-8.929 8.578-12.902 32.929-30.742 47.903-35.095 10.116-2.939 35.41-2.028 43.51 1.572 3.112 1.38 5.991 3.055 6.4 3.718 1.161 1.877-6.803 2.714-25.975 2.73-16.357.011-18.096.239-24.782 3.24-3.955 1.774-7.191 3.754-7.191 4.4 0 .646 1.14 2.773 2.531 4.728 1.964 2.756 3.486 3.556 6.786 3.556 8.486 0 13.727 9.314 9.536 16.956-3.262 5.948-5.484 7.06-10.2 5.107-4.749-1.969-7.43-6.844-7.43-13.522 0-3.618-1.052-6.574-3.725-10.456-3.726-5.413-3.726-5.413-7.037-3.318-10.789 6.829-23.503 16.964-23.503 18.736 0 2.853 15.108 14.731 24.215 19.04 9.14 4.325 25.221 6.998 38.196 6.355 9.106-.453 11.802-1.171 21.619-5.764l11.218-5.245 7.169 5.943c3.944 3.266 8.533 6.839 10.199 7.937 3.028 1.995 3.028 1.995.581 4.745-2.358 2.651-2.984 2.725-17.131 2.004-21.133-1.075-39.977 2.032-53.236 8.774-6.259 3.182-6.721 3.719-6.604 7.636.07 2.319 2.661 10.608 5.762 18.421 3.627 9.143 5.933 17.116 6.471 22.37.461 4.49 1.25 8.417 1.755 8.729.505.313 3.169-3.219 5.917-7.846 8.344-14.044 26.068-25.259 49.727-31.465 6.729-1.766 12.575-3.746 12.986-4.401.411-.655 1.07-5.135 1.465-9.957.394-4.823 1.812-11.695 3.151-15.273l2.436-6.503-7.751-10.043c-7.389-9.573-7.788-10.438-8.541-18.583-.436-4.696-1.085-11.076-1.441-14.178-.652-5.635-.652-5.635 6.477-6.973 3.92-.736 10.223-1.697 14.007-2.135 6.88-.796 6.88-.796 7.45 3.089l.569 3.887-10.204-.85c-10.205-.848-10.205-.848-10.205 2.355 0 2.82.492 3.204 4.113 3.204 2.261 0 6.667.35 9.791.778 4.445.609 5.676 1.273 5.676 3.06 0 2.024-1.039 2.281-9.179 2.281-7.26 0-9.217.383-9.361 1.834a323.493 323.493 0 0 0-.306 3.265c-.086.991 2.546 1.342 8.589 1.147 7.247-.235 8.847.068 9.513 1.805 1.096 2.857.31 3.369-6.344 4.135-4.011.46-5.762 1.219-5.762 2.497 0 1.375 1.993 1.999 7.955 2.494 6.293.524 9.338 1.545 14.573 4.893 6.396 4.09 7.089 4.247 20.581 4.675 16.419.521 21.653-.954 29.696-8.381 5.167-4.771 5.203-4.861 4.646-11.892-.651-8.259-7.197-20.554-13.229-24.849-6.263-4.459-24.187-4.805-29.831-.576-2.268 1.7-2.254 1.954.612 11.063 2.273 7.227 3.659 9.702 6.156 11.01 4.134 2.165 5.469 7.195 2.935 11.061-2.607 3.982-7.319 4.948-12.375 2.537-5.392-2.571-6.516-6.831-3.082-11.657 1.413-1.983 2.559-4.898 2.544-6.477-.037-4.458-3.172-15.127-4.391-14.944-.601.092-2.331.541-3.846 1-3.726 1.131-3.648-1.735.145-5.297 3.864-3.631 18.411-8.658 25.141-8.691 9.859-.048 18.417 3.537 25.456 10.664 8.499 8.604 9.435 12.346 8.403 33.62-.904 18.706-.471 20.383 8.274 31.838 9.045 11.848 9.049 13.968.046 31.216-8.599 16.478-8.982 17.825-7.6 26.721 1.97 12.661 5.646 22.576 10.267 27.691 5.828 6.45 7.466 10.17 5.512 12.521-.828.999-5.177 3.832-9.664 6.292-10.67 5.854-53.59 33.407-64.101 41.149-4.519 3.33-10.179 8.725-12.576 11.987-2.397 3.265-6.32 7.659-8.719 9.767-5.164 4.532-6.404 3.962-10.975-5.054-1.634-3.225-6.45-10.141-10.707-15.376-10.418-12.813-27.741-36.489-27.741-37.917 0-1.906 5.51-6.475 7.808-6.475 4.398 0 6.74 2.649 9.989 11.304 5.154 13.72 13.871 29.962 17.908 33.356 4.798 4.038 7.158 3.871 12.884-.91 2.62-2.188 14.001-9.451 25.291-16.14 19.893-11.786 34.141-22.369 39.033-28.987 1.909-2.582 2.106-3.711 1.009-5.761-1.175-2.199-2.409-2.522-8.997-2.361-4.198.103-13.141-.479-19.871-1.294-8.99-1.087-16.946-1.155-29.983-.257-9.758.671-23.259 1.23-29.999 1.241-9.894.014-13.137.491-16.823 2.466-2.705 1.45-6.936 2.456-10.385 2.466-8.241.026-9.843 1.288-7.963 6.271.82 2.174 1.261 4.182.979 4.464-.282.283-4.541.967-9.463 1.521-4.921.555-16.438 2.394-25.589 4.086-9.152 1.693-22.511 3.759-29.689 4.595-8.855 1.031-13.571 2.134-14.678 3.436-.896 1.055-2.889 6.702-4.423 12.545-3.448 13.113-2.906 16.699 4.328 28.611 2.981 4.911 5.421 9.326 5.421 9.808 0 .482-1.927 3.229-4.283 6.104-2.356 2.875-4.283 5.755-4.283 6.397 0 2.519 6.558 12.723 9.356 14.557 2.39 1.565 4.902 1.778 13.123 1.111 8.115-.658 12.613-.293 22.295 1.806 11.038 2.394 14.17 2.55 34.754 1.741 12.689-.5 25.317-1.642 28.758-2.596 3.375-.938 12.471-2.816 20.21-4.173 15.527-2.721 14.375-1.984 27.535-17.633 4.738-5.633 5.17-5.85 13.463-6.777 12.437-1.386 40.826-13.772 58.666-25.594 19.316-12.801 37.493-26.158 38.721-28.451 1.265-2.364-1.138-17.696-6.974-44.487-1.027-4.711-4.828-23.435-8.447-41.61-9.007-45.228-19.176-79.387-27.394-92.019-6.415-9.86-15.192-19.283-20.166-21.641-6.567-3.116-13.523-2.399-34.45 3.554-21.727 6.179-34.262 8.486-41.116 7.568-2.527-.338-9.541-3.471-15.588-6.962-12.467-7.195-21.314-10.277-34.943-12.171-12.997-1.808-20.77-1.528-29.906 1.084"/><path style="fill:#000" d="M220.309 272.48c-3.445.887-7.744 12.057-10.584 27.5-1.404 7.62-2.802 15.047-3.111 16.503-.464 2.197.849 3.478 7.696 7.505 4.543 2.673 15.967 9.515 25.392 15.209 21.045 12.712 46.64 26.2 60.814 32.049 11.593 4.783 12.001 4.896 12.001 3.316 0-.59-5.645-3.41-12.544-6.267-15.452-6.399-34.906-18.7-36.604-23.143-1.19-3.116-4.699-28.531-4.699-34.027 0-1.54.414-2.799.919-2.798.505 0 4.222 3.02 8.26 6.711 4.038 3.691 7.709 6.718 8.158 6.729 1.969.047 9.019 10.732 12.765 19.35 4.839 11.129 7.261 12.979 6.343 4.842-.351-3.12-3.554-11.592-7.363-19.487-5.295-10.968-8.043-15.136-12.811-19.422-6.114-5.495-50.027-35.56-51.553-35.296-.45.078-1.835.403-3.079.724m176.929 15.327c-6.193 1.297-5.824 2.856.943 4 7.083 1.197 9.775 5.174 9.845 14.544.056 7.483.056 7.483 12.26 18.375 15.689 14.002 25.664 21.725 27.345 21.178 2.724-.886 13.381-27.345 15.021-37.288.868-5.264-.589-6.772-10.384-10.759-6.618-2.693-11.029-3.5-22.883-4.188-12.102-.704-15.761-1.389-20.804-3.905-5.225-2.605-6.882-2.893-11.343-1.959m-41.026 55.786c-15.096 19.499-18.53 22.789-28.664 27.486-3.502 1.624-7.214 3.653-8.251 4.514-2.361 1.96-2.457 7.835-.158 9.743 2.48 2.057 8.754 2.318 8.352.345-.617-3.022 2.281-6.397 8.015-9.331 3.724-1.904 6.849-4.725 8.811-7.953 4.402-7.238 4.529-7.119 6.841 6.318.731 4.245 1.101 4.589 4.938 4.589 3.77 0 4.146-.328 4.146-3.583 0-1.972-.571-7.703-1.273-12.74-1.154-8.296-1.046-9.529 1.154-13.148 2.428-3.992 2.428-3.992 3.7-1.029 1.026 2.388 7.433 27.255 7.433 28.844 0 .944 8.466.356 9.077-.629.36-.583-.149-4.85-1.132-9.484-.983-4.632-1.795-12.142-1.807-16.684-.019-7.866.116-8.26 2.862-8.26 3.064 0 3.155.296 8.34 26.617 1.505 7.649 1.505 7.649 6.768 7.649 2.894 0 5.257-.414 5.25-.919-.006-.504-.827-7.801-1.825-16.215-.997-8.413-1.819-15.436-1.825-15.604-.005-.168 1.082-.307 2.415-.307 2.488 0 2.879.951 4.277 10.402.398 2.693 1.632 8.889 2.742 13.766l2.019 8.873h11.79v-7.955c0-4.377.411-7.956.918-7.954.504.001 2.488 2.489 4.409 5.53 1.92 3.037 5.859 7.464 8.749 9.834l5.258 4.309 4.375-2.968 4.374-2.968-3.862-5.339c-10.497-14.506-22.672-28.643-30.397-35.29l-8.57-7.376-13.125-.012c-7.218-.008-15.095-.34-17.505-.738-4.381-.725-4.381-.725-18.619 17.661m-155.473-6.813c-1.1 4.205-3.967 17.009-6.371 28.451-7.835 37.291-6.158 34.922-30.429 42.967-19.737 6.542-26.044 9.508-45.844 21.562-11.352 6.911-16.776 11.258-26.792 21.472-6.906 7.044-12.896 14.159-13.311 15.814-1.725 6.875 4.777 12.095 23.115 18.556 12.59 4.436 26.068 6.331 45.196 6.355 31.699.041 55.232-13.249 57.865-32.673.35-2.593.866-11.39 1.143-19.543.551-16.259 1.539-19.338 8.281-25.801 6.026-5.78 9.98-7.019 42.109-13.175 42.994-8.238 43.903-8.456 44.323-10.637.322-1.669-2.24-2.021-18.962-2.602-10.632-.371-26.493-1.792-35.241-3.157-8.75-1.368-21.02-2.87-27.269-3.341-6.247-.471-11.652-1.33-12.009-1.912-.36-.581-.283-2.219.168-3.641.787-2.483 1.362-2.56 14.458-1.914 12.641.622 45.221 3.952 66.914 6.838 5.07.674 11.924.839 15.229.368l6.009-.86-11.558-4.566c-6.357-2.513-16.238-6.147-21.959-8.078-12.923-4.36-19.404-7.634-40.823-20.613-14.733-8.926-30.316-17.521-31.775-17.521-.256 0-1.365 3.442-2.465 7.649m251.699 43.746c-5.345 2.156-5.184 13.108.245 16.667 3.946 2.584 7.292 1.442 5.512-1.881-1.469-2.743-1.725-9.88-.36-9.906.504-.011 1.742-.541 2.748-1.175 1.57-.992 1.482-1.419-.612-3.002-2.78-2.101-3.825-2.198-7.535-.703"/><path style="fill:#000" d="M217.953 460.947c-.666 5.906-2.377 8.075-13.853 17.547-4.55 3.756-6.399 11.566-3.632 15.333 1.498 2.039 3.069 2.309 11.873 2.04 6.161-.187 10.702-.91 11.556-1.834 1.877-2.033 4.178-11.839 4.178-17.809 0-4.88-6.468-21.044-8.42-21.044-.579 0-1.343 2.595-1.702 5.767"/><text x="15" y="45" font-size="28" font-family="fantasy" font-weight="bold">';

    string svgPartTwo = '</text></svg>';

    string public tld;

    mapping(string => address) public domains; // takes name returns address
    mapping(string => string) public records;   // takes name returns why

    constructor(string memory _tld ) payable ERC721("Dark Sider", "DS") {
        tld = _tld;
    }

    // This function will give us the price of a domain based on length
    function price(string calldata _name) public pure returns (uint) {
        uint len = StringUtils.strlen(_name);
        require(len > 0);
            if (len <= 5) {
            return 5 * 10**17;          // 0.5 MATIC
        } else if (len == 6) {
            return 3 * 10**17;          // 0.3 MATIC
        } else {
            return 1 * 10**17;          // 0.1 MATIC
        }
  }

    // A register function that adds their names to our mapping
    function register(string calldata name) public payable {
        require(domains[name] == address(0), "This domain is already registered.");
        uint _price = price(name);
        require(msg.value >= _price, "Not enough Matic paid.");
        
        // Combine the name passed into the function  with the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));

        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
        abi.encodePacked(
            '{"name": "',
            _name,
            '", "description": "A domain on the Dark Sider network.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(finalSvg)),
            '","length":"',
            strLen,
            '"}'
        ));

        string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;
        _tokenIds.increment();
  }

    // This will give us the domain owners' address
    function getAddress(string calldata _name) public view returns (address) {
        return domains[_name];
    }

    function setDark(string calldata _name, string calldata _why) public {
        require(domains[_name] == msg.sender, "You are not the owner of this domain.");
        records[_name] = _why;
    }

    function getDark(string calldata _name) public view returns(string memory) {
        return records[_name];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// Source:
// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}