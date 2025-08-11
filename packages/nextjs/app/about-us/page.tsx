import React from "react";
import Image from "next/image";

const teamMembers = [
  {
    name: "Kimberly Cascante",
    image: "/Kim.png",
    github: "https://github.com/kimcascante",
  },
  {
    name: "Jefferson Calderon",
    image: "/Jeff.jpeg",
    github: "https://github.com/xJeffx23",
  },
  {
    name: "Joseph Poveda",
    image: "/Joseph.jpeg",
    github: "https://github.com/josephpdf/",
  },
  {
    name: "Andrés Villanueva",
    image: "/Andres.jpeg",
    github: "https://github.com/drakkomaximo",
  },
  {
    name: "David Melendez",
    image: "/David.jpeg",
    github: "https://github.com/davidmelendez",
  },
];

const AboutUsPage = () => {
  return (
    <div className="text-white text-center py-20">
      <h1 className="text-4xl font-bold text-left">About Starklotto</h1>

      <div className="flex">
        <div className="w-1/2 pr-8">
          <div>
            <h2 className="font-bold text-left mt-8">MISSION STATEMENT</h2>
            <p className="mt-4 text-lg text-left">
              At StarkLotto, our mission is to revolutionize the lottery
              experience through blockchain technology. We create a secure,
              transparent and accessible environment where everyone has the
              opportunity to win and be part of the future of digital lotteries.
            </p>
          </div>
          <div>
            <h2 className="font-bold text-left mt-8">VISION STATEMENT</h2>
            <p className="mt-4 text-lg text-left">
              To be the leading decentralized lottery platform, recognized for
              its innovation, security and commitment to the global community.
            </p>
          </div>
          <div>
            <h2 className="font-bold text-left mt-8">Why choose us?</h2>
            <ul className="mt-4 text-lg text-left list-disc list-inside">
              <li>
                100% Decentralized Lottery: Each draw is verifiable and cannot
                be manipulated.
              </li>
              <li>Crypto Prizes: Win prizes in ETH and exclusive NFTs.</li>
              <li>
                Secure Gaming: Integration with secure wallets such as Braavos.
              </li>
            </ul>
          </div>
        </div>
        <div className="w-1/2 pl-8">
          <h2 className="font-bold mt-8 uppercase text-center mb-4">
            Meet the Minds Behind StarkLotto
          </h2>
          <a href="https://github.com/future-minds7" target="_blank">
            <Image
              src="/FutureMindsLogo.png"
              alt="Meet the Minds Behind StarkLotto"
              className="mt-4 mx-auto rounded-full"
              width={160}
              height={160}
            />
          </a>
          <div className="flex mt-4 justify-center">
            {teamMembers.map((member) => (
              <a href={member.github} key={member.name} target="_blank">
                <Image
                  src={member.image}
                  alt={member.name}
                  className="w-20 mr-2 rounded-full"
                  width={80}
                  height={80}
                />
              </a>
            ))}
          </div>
          <p className="mt-4 text-lg text-center">
            We are a passionate team of developers, designers, and innovators
            participating in the Winter Hackathon 2025. Our mission is to build
            a decentralized lottery system leveraging blockchain technology to
            ensure transparency, fairness, and on-chain prize distribution
          </p>
        </div>
      </div>
    </div>
  );
};

export default AboutUsPage;
