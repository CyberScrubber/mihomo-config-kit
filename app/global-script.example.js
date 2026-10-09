// 将本文件内容粘贴到 Clash Verge Rev 的「全局扩展脚本」中。
// 只修改下面两台节点的 server、port、uuid、servername、public-key、short-id。
// 节点名称必须与项目中的策略组保持一致。旧版脚本升级时只需替换 3 种名称，不必重填服务器参数。
function main(config, profileName) {
  const groups = config["proxy-groups"];
  const personalProfile = Array.isArray(groups) && groups.some(group =>
    group.name === "🇺🇸 美国自动" &&
    Array.isArray(group.proxies) &&
    group.proxies.includes("🌵 US-Phoenix") &&
    group.proxies.includes("🌴 US-LosAngeles")
  );
  if (!personalProfile) return config;

  config.proxies = [
    {
      name: "🌵 US-Phoenix",
      type: "vless",
      server: "REPLACE_PHOENIX_SERVER",
      port: 443,
      uuid: "REPLACE_PHOENIX_UUID",
      network: "tcp",
      tls: true,
      udp: true,
      "client-fingerprint": "chrome",
      servername: "REPLACE_PHOENIX_SNI",
      flow: "xtls-rprx-vision",
      "reality-opts": {
        "public-key": "REPLACE_PHOENIX_PUBLIC_KEY",
        "short-id": "REPLACE_PHOENIX_SHORT_ID"
      }
    },
    {
      name: "🌴 US-LosAngeles",
      type: "vless",
      server: "REPLACE_LA_SERVER",
      port: 443,
      uuid: "REPLACE_LA_UUID",
      network: "tcp",
      tls: true,
      udp: true,
      "client-fingerprint": "chrome",
      servername: "REPLACE_LA_SNI",
      flow: "xtls-rprx-vision",
      "reality-opts": {
        "public-key": "REPLACE_LA_PUBLIC_KEY",
        "short-id": "REPLACE_LA_SHORT_ID"
      }
    }
  ];
  return config;
}
