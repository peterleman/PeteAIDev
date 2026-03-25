import { createElement } from '@lwc/engine-dom';
import Pong from 'c/pong';

describe('c-pong', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the arcade shell and game switcher', () => {
        const element = createElement('c-pong', {
            is: Pong
        });

        document.body.appendChild(element);

        const score = element.shadowRoot.querySelector('.score');
        const buttons = element.shadowRoot.querySelectorAll('lightning-button');
        const arena = element.shadowRoot.querySelector('.arena');
        const modeSwitcher = element.shadowRoot.querySelector('.mode-switcher');

        expect(score.textContent).toBe('0 : 0');
        expect(buttons).toHaveLength(4);
        expect(arena).not.toBeNull();
        expect(modeSwitcher).not.toBeNull();
    });
});
