use iced::executor;
use iced::mouse;
use iced::widget::canvas::{Cache, Geometry, Path};
use iced::widget::{canvas, container};
use iced::{
    Application, Color, Command, Element, Length, Point, Rectangle, Renderer, Settings, Size, Theme,
};

pub fn main() -> iced::Result {
    PixelEditor::run(Settings {
        antialiasing: true,
        ..Settings::default()
    })
}

struct PixelEditor {
    canvas: Cache,
    positions: Vec<Point>,
}

#[derive(Debug, Clone, Copy)]
enum Message {
    Placed(Point),
}

impl Application for PixelEditor {
    type Executor = executor::Default;
    type Message = Message;
    type Theme = Theme;
    type Flags = ();

    fn new(_flags: ()) -> (Self, Command<Message>) {
        (
            Self {
                canvas: Cache::default(),
                positions: Vec::new(),
            },
            Command::none(),
        )
    }

    fn title(&self) -> String {
        String::from("Clock - Iced")
    }

    fn update(&mut self, message: Message) -> Command<Message> {
        match message {
            Message::Placed(point) => {
                self.positions.push(point);
                self.canvas.clear();
            }
        }

        Command::none()
    }

    fn view(&self) -> Element<Message> {
        let canvas = canvas(self as &Self)
            .width(Length::Fill)
            .height(Length::Fill);

        container(canvas)
            .width(Length::Fill)
            .height(Length::Fill)
            .padding(0)
            .into()
    }

    // fn subscription(&self) -> Subscription<Message> {
    //     iced::time::every(std::time::Duration::from_millis(500)).map(|_| {
    //         Message::Tick(
    //             time::OffsetDateTime::now_local()
    //                 .unwrap_or_else(|_| time::OffsetDateTime::now_utc()),
    //         )
    //     })
    // }
}

impl canvas::Program<Message> for PixelEditor {
    type State = Option<Message>;

    fn update(
        &self,
        state: &mut Self::State,
        event: canvas::Event,
        _bounds: Rectangle,
        cursor: mouse::Cursor,
    ) -> (canvas::event::Status, Option<Message>) {
        match event {
            canvas::Event::Mouse(mouse::Event::ButtonPressed(mouse::Button::Left)) => {
                *state = cursor
                    .position()
                    .map(|point| {
                        Point::new((point.x / 16.).floor() * 16., (point.y / 16.).floor() * 16.)
                    })
                    .map(Message::Placed);
                (canvas::event::Status::Captured, state.take())
            }
            _ => (canvas::event::Status::Ignored, state.take()),
        }
    }

    fn draw(
        &self,
        _state: &Self::State,
        renderer: &Renderer,
        _theme: &Theme,
        bounds: Rectangle,
        _cursor: mouse::Cursor,
    ) -> Vec<Geometry> {
        let canvas = self.canvas.draw(renderer, bounds.size(), |frame| {
            // Set the background color
            let background = Path::rectangle(Point::ORIGIN, frame.size());
            frame.fill(&background, Color::from_rgb(0.1, 0.2, 0.3));

            // Draw all positions
            for pos in &self.positions {
                let cell = Path::rectangle(*pos, Size::new(16.0, 16.0));
                frame.fill(&cell, Color::BLACK);
            }
        });

        vec![canvas]
    }
}
