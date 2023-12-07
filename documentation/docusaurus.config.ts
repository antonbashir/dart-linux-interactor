import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const organizationName = "antonbashir";
const projectName = "dart-linux-interactor";
const baseUrl = `/${projectName}/`;

const config: Config = {
  title: 'Dart Linux Interactor',
  tagline: 'Dart Linux Interactor',
  favicon: 'images/favicon.jpg',
  url: `https://${organizationName}.github.io`,
  baseUrl,
  organizationName,
  projectName,
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },
  presets: [
    [
      'classic',
      {
        docs: {
          routeBasePath: '/',
          sidebarPath: './sidebars.ts',
          editUrl: `https://github.com/${organizationName}/${projectName}/tree/main/documentation`,
        },
        pages: false,
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: true,
      respectPrefersColorScheme: false,
    },
    navbar: {
      title: 'Dart Linux Interactor',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'documentationSidebars',
          position: 'left',
          label: 'Documentation',
        },
        {
          href: 'https://github.com/antonbashir/dart-linux-interactor',
          label: 'Source',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Author',
          items: [
            {
              label: 'About me',
              href: 'https://antonbashir.github.io',
            },
          ],
        },
        {
          title: 'Projects',
          items: [
            {
              label: 'dart-iouring-transport',
              href: 'https://github.com/antonbashir/dart-iouring-transport',
            }
          ],
        },
        {
          title: 'Samples',
          items: [
            {
              label: 'dart-iouring-sample',
              href: 'https://github.com/antonbashir/dart-transport-sample',
            },
          ],
        },
        {
          title: 'References',
          items: [
            {
              label: 'io_uring',
              href: 'https://github.com/espoal/awesome-iouring',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} ${organizationName}`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
