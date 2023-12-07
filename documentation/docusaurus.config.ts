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
            {
              label: 'Telegram',
              href: 'https://t.me/a_bashirov',
            },
            {
              label: 'Linkedin',
              href: 'https://www.linkedin.com/in/anton-bashirov',
            },
          ],
        },
        {
          title: 'Projects',
          items: [
            {
              label: 'dart-iouring-transport',
              href: 'https://github.com/antonbashir/dart-iouring-transport',
            },
            {
              label: 'dart-tarantool-storage',
              href: 'https://github.com/antonbashir/dart-tarantool-storage',
            },
            {
              label: 'dart-linux-interactor',
              href: 'https://github.com/antonbashir/dart-linux-interactor',
            },
            {
              label: 'dart-reactive-transport',
              href: 'https://github.com/antonbashir/dart-reactive-transport',
            }
          ],
        },
        {
          title: 'Samples',
          items: [
            {
              label: 'dart-transport-sample',
              href: 'https://github.com/antonbashir/dart-transport-sample',
            },
            {
              label: 'dart-tarantool-sample',
              href: 'https://github.com/antonbashir/dart-tarantool-sample',
            },
            {
              label: 'dart-linux-sample',
              href: 'https://github.com/antonbashir/dart-linux-sample',
            },
            {
              label: 'dart-reactive-sample',
              href: 'https://github.com/antonbashir/dart-reactive-sample',
            }
          ],
        },
        {
          title: 'References',
          items: [
            {
              label: 'Dart',
              href: 'https://dart.dev/',
            },
            {
              label: 'Dart FFI',
              href: 'https://dart.dev/interop/c-interop',
            },
            {
              label: 'Flutter',
              href: 'https://flutter.dev/',
            },
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
