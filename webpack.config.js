const path = require('path');
const webpack = require('webpack');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const nodeModulesPath = path.resolve(__dirname, 'node_modules');
const assetPrefix = 'logging-';

const config = {
  mode: 'production',
  devtool: 'eval',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: assetPrefix + '[contenthash].js',
    publicPath: '/',
  },
  entry: {
    logging: './component/index.tsx'
  },
  plugins: [
    new webpack.DefinePlugin({
      'process.env': {
        NODE_ENV: JSON.stringify('production'),
      },
    }),
    new webpack.PrefetchPlugin('react'),
    new webpack.PrefetchPlugin('react-dom/server.browser.js'),
    new MiniCssExtractPlugin({ filename: assetPrefix + '[contenthash].css' }),
  ],
  module: {
    unknownContextCritical: false,
    rules: [
      {
        test: /\.tsx?$/,
        use: [
          {
            loader: 'ts-loader',
            options: {
              transpileOnly: true
            },
          }
        ]
      },
      {
        test: /\.jsx?$/,
        use: 'babel-loader',
        exclude: [/node_modules/],
      },
      {
        test: /\.css$/,
        use: [
          MiniCssExtractPlugin.loader,
          {
            loader: 'css-loader',
            options: {
              esModule: true,
              import: false,
              modules: true,
            },
          },
        ]
      }
    ],
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './component'),
      react: path.join(nodeModulesPath, '/react'),
      'react-dom': path.join(nodeModulesPath, '/react-dom'),
    },
    extensions: ['.tsx', '.ts', '.js', '.jsx'],
  },
};

module.exports = config;
