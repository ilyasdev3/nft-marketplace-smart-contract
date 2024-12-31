// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable, ReentrancyGuard {
    struct Listing {
        uint256 price;
        address seller;
    }

    mapping(uint256 => Listing) private _listings;
    mapping(address => uint256) private _proceeds;

    event NFTMinted(uint256 tokenId, string tokenURI, address owner);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTSold(uint256 tokenId, uint256 price, address buyer, address seller);
    event ProceedsWithdrawn(address seller, uint256 amount);

    uint256 private _tokenIdCounter;

    constructor() ERC721("NFTMarketplace", "NFTM") Ownable(msg.sender) {}

    // Mint an NFT
    function mintNFT(string memory tokenURI) external {
        uint256 newTokenId = _tokenIdCounter;
        _tokenIdCounter += 1;

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        emit NFTMinted(newTokenId, tokenURI, msg.sender);
    }

    // List an NFT for sale
    function listNFT(uint256 tokenId, uint256 price) external nonReentrant {
        require(ownerOf(tokenId) == msg.sender, "Not the NFT owner");
        require(price > 0, "Price must be greater than zero");

        _listings[tokenId] = Listing({price: price, seller: msg.sender});

        approve(address(this), tokenId);
        emit NFTListed(tokenId, price, msg.sender);
    }

    // Buy an NFT
    function buyNFT(uint256 tokenId) external payable nonReentrant {
        Listing memory listing = _listings[tokenId];
        require(listing.price > 0, "NFT is not listed for sale");
        require(msg.value == listing.price, "Incorrect price sent");

        delete _listings[tokenId];
        _proceeds[listing.seller] += msg.value;

        _transfer(listing.seller, msg.sender, tokenId);
        emit NFTSold(tokenId, listing.price, msg.sender, listing.seller);
    }

    // Withdraw proceeds
    function withdrawProceeds() external nonReentrant {
        uint256 proceeds = _proceeds[msg.sender];
        require(proceeds > 0, "No proceeds to withdraw");

        _proceeds[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: proceeds}("");
        require(success, "Withdrawal failed");

        emit ProceedsWithdrawn(msg.sender, proceeds);
    }

    // View NFT listing details
    function getListing(uint256 tokenId) external view returns (uint256 price, address seller) {
        Listing memory listing = _listings[tokenId];
        return (listing.price, listing.seller);
    }

    // View proceeds for a seller
    function getProceeds(address seller) external view returns (uint256) {
        return _proceeds[seller];
    }

    // Override _baseURI to set a default base URI
    function _baseURI() internal view override returns (string memory) {
        return "https://api.example.com/metadata/";
    }
}
