import footnote from "markdown-it-footnote";
import { type DefaultTheme, defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  base: "/rime-wanxiang-slim/",
  lang: "zh-CN",
  title: "rime-wanxiang-slim",
  description: "万象拼音输入方案精简版",
  cleanUrls: true,
  lastUpdated: false,
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [],

    search: {
      provider: "local",
      options: searchOptions(),
    },

    sidebar: [
      {
        text: "开始",
        items: [
          { text: "简介", link: "/getting-started/introduction" },
          { text: "安装", link: "/getting-started/installation" },
          { text: "快速上手", link: "/getting-started/quick-start" },
        ],
      },
      {
        text: "自定义",
        items: [
          { text: "Rime 定制指南", link: "/customization/rime" },
          { text: "自定义词库", link: "/customization/dictionaries" },
        ],
      },
      {
        text: "功能详解",
        items: [
          { text: "辅助码", link: "/features/auxiliary-code" },
          { text: "辅助筛选 / 反查", link: "/features/reverse-lookup" },
          { text: "造词", link: "/features/user-dict" },
          { text: "其他功能", link: "/features/others" },
        ],
      },
    ],

    socialLinks: [
      {
        icon: "github",
        link: "https://github.com/Fidelxyz/rime-wanxiang-slim",
      },
    ],

    footer: {
      message: "基于 CC-BY-4.0 许可发布",
    },
    docFooter: {
      prev: "上一页",
      next: "下一页",
    },
    outline: {
      label: "页面导航",
    },
    notFound: {
      title: "页面未找到",
      quote:
        "但如果你不改变方向，并且继续寻找，你可能最终会到达你所前往的地方。",
      linkLabel: "前往首页",
      linkText: "带我回首页",
    },
    langMenuLabel: "多语言",
    returnToTopLabel: "回到顶部",
    sidebarMenuLabel: "菜单",
    darkModeSwitchLabel: "主题",
    lightModeSwitchTitle: "切换到浅色模式",
    darkModeSwitchTitle: "切换到深色模式",
    skipToContentLabel: "跳转到内容",
  },
  markdown: {
    config: (md) => {
      md.use(footnote);
    },
  },
});

function searchOptions(): Partial<DefaultTheme.LocalSearchOptions> {
  return {
    translations: {
      button: {
        buttonText: "搜索",
        buttonAriaLabel: "搜索",
      },
      modal: {
        displayDetails: "显示详细列表",
        resetButtonTitle: "重置搜索",
        backButtonTitle: "关闭搜索",
        noResultsText: "没有结果",
        footer: {
          selectText: "选择",
          selectKeyAriaLabel: "输入",
          navigateText: "导航",
          navigateUpKeyAriaLabel: "上箭头",
          navigateDownKeyAriaLabel: "下箭头",
          closeText: "关闭",
          closeKeyAriaLabel: "Esc",
        },
      },
    },
  };
}
