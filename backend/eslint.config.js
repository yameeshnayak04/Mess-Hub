// new_backend/eslint.config.js
//
// ESLint 9 "flat config". Deliberately minimal: the recommended rule set,
// plus eslint-config-prettier to switch off anything that would argue with
// Prettier about formatting.
const js = require('@eslint/js');
const prettier = require('eslint-config-prettier');
const globals = require('globals');

module.exports = [
  { ignores: ['node_modules/**'] },
  js.configs.recommended,
  prettier,
  {
    languageOptions: {
      ecmaVersion: 2023,
      sourceType: 'commonjs',
      globals: { ...globals.node },
    },
    rules: {
      // Allow deliberately-unused args when they are named with a leading
      // underscore - Express needs a 4-argument error handler even though
      // `next` goes unused inside it.
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    },
  },
];
